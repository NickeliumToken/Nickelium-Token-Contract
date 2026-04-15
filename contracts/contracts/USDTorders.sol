// SPDX-License-Identifier: Custom-License
/*This contract is part of Nickelium Token Ecosystem and is property of Destrier LLC. You are granted permission to use all functions of this contract intended for users. 
*However, copying, modifying, or distributing the code is strictly prohibited without explicit permission from the author.
*All rights reserved. Destrier LLC, registration number 20241316871 , Colorado , USA.*/

pragma solidity ^0.8.0;
import "./IAdminControl.sol";
import "./ICentral.sol";
import "./SharedStructs.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/Pausable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/utils/math/Math.sol";
import "./INickelium.sol";
import "./IEscrowHandler.sol";
import "./ITether.sol";

contract USDTorders is Pausable, ReentrancyGuard{
    mapping(address => bool) public authorizedAddresses;

    // Buy orders separate queues for Ether and USDT
    SharedStructs.Order[] public buyOrdersUSDT;
    // Sell orders separate queues for Ether and USDT
    SharedStructs.Order[] public sellOrdersUSDT;
    
    // Reference to Nickelium and USDT contracts
    IEscrowHandler public escrowHandler;
    ITether public USDTContract;
    INickelium public nickeliumContract;
    IAdminControl public adminControl; // Use the interface
    ICentral public centralContract;

    constructor() payable {
        authorizedAddresses[msg.sender] = true;
    }

    modifier onlyAuthorized() {
        require(authorizedAddresses[msg.sender], "Not authorized");
        _;
    }

    function setAuthorizedAddress(address _address, bool _status) public onlyAuthorized nonReentrant whenNotPaused {
        authorizedAddresses[_address] = _status;
    }

    address public owner;
    function setOwner(address newOwner) public onlyAuthorized {
        owner = newOwner;
    }

    function setContracts(
        address _USDTAddress,
        address _nickeliumAddress,
        address _adminControl,
        address _centralAddress,
        address _escrowHandler
    ) public onlyAuthorized nonReentrant whenNotPaused {
        _USDTAddress = _USDTAddress;
        USDTContract = ITether(_USDTAddress);
        nickeliumContract = INickelium(_nickeliumAddress);
        adminControl = IAdminControl(_adminControl);
        centralContract = ICentral(_centralAddress);
        escrowHandler = IEscrowHandler(_escrowHandler);
    }

   

    function approveUSDT(address adminControlAddress, uint256 transferAmount) external onlyAuthorized whenNotPaused {
    USDTContract.approve(adminControlAddress, transferAmount);
}



  function getBuyOrdersUSDT() public view returns (SharedStructs.Order[] memory) {
    return buyOrdersUSDT;
}
  
  function getSellOrdersUSDT() external view returns (SharedStructs.Order[] memory) {
    return sellOrdersUSDT;
}
    
    function sellOrdersUSDTLength() public view returns (uint) {
        return sellOrdersUSDT.length;
    }

    
    function buyOrdersUSDTLength() public view returns (uint) {
        return buyOrdersUSDT.length;
    }

   
    function getSellOrdersUSDT(uint index) public view returns (SharedStructs.Order memory) {
        return sellOrdersUSDT[index];
    }

    
    function getBuyOrdersUSDT(uint index) public view returns (SharedStructs.Order memory) {
        return buyOrdersUSDT[index];
    }
    
    
    function getHighestBuyOrderUSDT() public view returns (SharedStructs.Order memory) {
        return buyOrdersUSDT[0];
    }

    function getLowestSellOrderUSDT() public view returns (SharedStructs.Order memory) {
        return sellOrdersUSDT[0];
    }
    
   
    function removeBuyOrderUSDT(uint256 index) public onlyAuthorized {
        require(index < buyOrdersUSDT.length, "Index out of bounds");

        for (uint256 i = index; i < buyOrdersUSDT.length - 1; i++) {
            buyOrdersUSDT[i] = buyOrdersUSDT[i + 1];
        }
        buyOrdersUSDT.pop();
    }

    function removeSellOrderUSDT(uint256 index) public onlyAuthorized {
        require(index < sellOrdersUSDT.length, "Index out of bounds");

        for (uint256 i = index; i < sellOrdersUSDT.length - 1; i++) {
            sellOrdersUSDT[i] = sellOrdersUSDT[i + 1];
        }
        sellOrdersUSDT.pop();
    }
    

    function addBuyOrder(
    uint256 _orderID,
    address buyer,
    uint256 _price,
    uint256 _amount,
    SharedStructs.AssetType _assetType,
    SharedStructs.PaymentMethod _priceCurrency,
    bool authorizedBuyersOnly
) external onlyAuthorized nonReentrant whenNotPaused {
    // Create the new order
    SharedStructs.Order memory newOrder = SharedStructs.Order({
        orderID: _orderID,
        user: payable(buyer),
        price: _price,
        amount: _amount,
        fulfilledAmount: 0,
        assetType: _assetType,
        priceCurrency: _priceCurrency,
        authorizedBuyersOnly: authorizedBuyersOnly
    });
	require(_price >= centralContract.LMEprice(), "Order price must be at least the current LME price");
	 if (buyOrdersUSDT.length == 0) {
    // If the buyOrdersUSDT array is empty, execute matching logic with opposite orders (sellOrdersUSDT)
    matchNewOrderUSDT(newOrder, true, true); // true for buy order
} else {
    // If the buyOrdersUSDT array is not empty, check if the new order's price is higher than the first buy order's price
    if (newOrder.price > buyOrdersUSDT[0].price) {
        // Execute matching logic
        matchNewOrderUSDT(newOrder, true, true); // true for buy order
    } else {
        // Insert the new order into the correct position
        insertOrderInSortedPosition(buyOrdersUSDT, newOrder); // true for buy order
    }
}

}

    function matchNewOrderUSDT(SharedStructs.Order memory newOrder, bool isBuyOrder, bool isNewOrder) internal whenNotPaused {
    uint256 tradeAmount;
    uint256 remainingAmount = newOrder.amount;

    SharedStructs.Order[] storage oppositeOrders = isBuyOrder ? sellOrdersUSDT : buyOrdersUSDT;

    uint256 i = 0;
    while (i < oppositeOrders.length) {
        SharedStructs.Order storage oppositeOrder = oppositeOrders[i];

        if (!isBuyOrder && oppositeOrder.authorizedBuyersOnly) {
            if (!centralContract.isAuthorizedBuyer(newOrder.user)) {
                i++;
                continue;
            }
        }

        // Matching logic based on price
        bool isMatch = isBuyOrder ? (newOrder.price >= oppositeOrder.price) : (newOrder.price <= oppositeOrder.price);
        if (!isMatch) break;

        // Calculate trade amount and adjust remaining amount
        tradeAmount = Math.min(remainingAmount, oppositeOrder.amount);
        executeTradeUSDT(newOrder, oppositeOrder, tradeAmount, isBuyOrder);

        remainingAmount -= tradeAmount;
        oppositeOrder.amount -= tradeAmount;

        if (oppositeOrder.amount == 0) {
            removeOrderFromList(oppositeOrders, i);
            // Do NOT increment i here; the next element is now at i
        } else {
            i++; // Move to next only if current wasn't removed
        }

        if (remainingAmount == 0) break;
    }

    SharedStructs.Order[] storage targetOrders = isBuyOrder ? buyOrdersUSDT : sellOrdersUSDT;

    // If there is a remaining amount, update the existing order or insert it into the list
    if (remainingAmount > 0) {
        newOrder.amount = remainingAmount;

        bool orderFound = false;
        for (uint256 j = 0; j < targetOrders.length; j++) {
            if (targetOrders[j].orderID == newOrder.orderID) {
                // Update the existing order
                targetOrders[j] = newOrder;
                orderFound = true;
                break;
            }
        }
		
		if (orderFound) {
        // Order was found and already updated, no need to re-insert
		return;
    } else {
        // Check and remove worst order if capacity is reached
        if (targetOrders.length >= 20) {
            if (isBuyOrder) {
                removeWorstPricedOrder(targetOrders, SharedStructs.PaymentMethod.USDT);
            } else {
                removeWorstPricedSellOrder(targetOrders, newOrder.assetType);
            }
        }

            // Find the correct index for ascending (sell) or descending (buy) order
            uint256 insertIndex = 0;
            if (targetOrders.length > 0) {
                while (
                    insertIndex < targetOrders.length &&
                    (isBuyOrder ? newOrder.price <= targetOrders[insertIndex].price : newOrder.price >= targetOrders[insertIndex].price)
                ) {
                    insertIndex++;
                }
            }

            // Insert the order without redundant shifting
            targetOrders.push(newOrder);
            for (uint256 j = targetOrders.length - 1; j > insertIndex; j--) {
                targetOrders[j] = targetOrders[j - 1];
            }
            targetOrders[insertIndex] = newOrder;
        }
    } else if (!isNewOrder) {
    // Find and remove the order from targetOrders
    for (uint256 j = 0; j < targetOrders.length; j++) {
        if (targetOrders[j].orderID == newOrder.orderID) {
            removeOrderFromList(targetOrders, j);
            break;
        }
    }
}
}

/*function addBuyOrder(
    uint256 _orderID,
    address buyer,
    uint256 _price,
    uint256 _amount,
    SharedStructs.AssetType _assetType,
    SharedStructs.PaymentMethod _priceCurrency,
    bool authorizedBuyersOnly
) external onlyAuthorized nonReentrant whenNotPaused {
    // Create the new order
    SharedStructs.Order memory newOrder = SharedStructs.Order({
        orderID: _orderID,
        user: payable(buyer),
        price: _price,
        amount: _amount,
        fulfilledAmount: 0,
        assetType: _assetType,
        priceCurrency: _priceCurrency,
        authorizedBuyersOnly: authorizedBuyersOnly
    });
	require(_price >= centralContract.LMEprice(), "Order price must be at least the current LME price");
	 if (buyOrdersUSDT.length == 0) {
    // If the buyOrdersUSDT array is empty, execute matching logic with opposite orders (sellOrdersUSDT)
    matchNewOrderUSDT(newOrder, true); // true for buy order
} else {
    // If the buyOrdersUSDT array is not empty, check if the new order's price is higher than the first buy order's price
    if (newOrder.price > buyOrdersUSDT[0].price) {
        // Execute matching logic
        matchNewOrderUSDT(newOrder, true); // true for buy order
    } else {
        // Insert the new order into the correct position
        insertOrderInSortedPosition(buyOrdersUSDT, newOrder); // true for buy order
    }
}

}


   function matchNewOrderUSDT(SharedStructs.Order memory newOrder, bool isBuyOrder) internal whenNotPaused {
    require(msg.sender == address(escrowHandler), "Only authorized address can call match orders");

    uint256 tradeAmount;
    uint256 remainingAmount = newOrder.amount;

    // Determine the list of opposite orders
    SharedStructs.Order[] storage oppositeOrders;
    if (isBuyOrder) {
        oppositeOrders = sellOrdersUSDT; // Match against sell orders
    } else {
        oppositeOrders = buyOrdersUSDT; // Match against buy orders
    }

    // Iterate through the opposite orders and match them with the new order
    for (uint256 i = 0; i < oppositeOrders.length; i++) {
        SharedStructs.Order storage oppositeOrder = oppositeOrders[i];

        // Check if the seller only accepts payments from authorized buyers (for sell orders)
        if (!isBuyOrder && oppositeOrder.authorizedBuyersOnly) {
            if (!centralContract.isAuthorizedBuyer(newOrder.user)) {
                continue; // Skip this sell order if the buyer is not authorized
            }
        }

        // Check if the prices match
        bool isMatch = false;
        if (isBuyOrder) {
            // For buy orders: newOrder.price >= oppositeOrder.price
            isMatch = newOrder.price >= oppositeOrder.price;
        } else {
            // For sell orders: newOrder.price <= oppositeOrder.price
            isMatch = newOrder.price <= oppositeOrder.price;
        }

        // If the prices no longer match, stop matching
        if (!isMatch) {
            break;
        }

        // Execute the trade
        tradeAmount = Math.min(remainingAmount, oppositeOrder.amount);
        executeTradeUSDT(newOrder, oppositeOrder, tradeAmount, isBuyOrder);

        // Update the remaining amount
        remainingAmount -= tradeAmount;

        // Update the opposite order amount
        oppositeOrder.amount -= tradeAmount;

        // Remove the opposite order if fully matched
        if (oppositeOrder.amount == 0) {
            removeOrderFromList(oppositeOrders, i);
            i--; // Adjust the index after removal
        }

        // If the new order is fully matched, exit the loop
        if (remainingAmount == 0) {
            break;
        }
    }

    // If there is a remaining amount, insert the new order into the list
    if (remainingAmount > 0) {
        newOrder.amount = remainingAmount;

        // Determine the list to insert the new order into
        SharedStructs.Order[] storage targetOrders;
        if (isBuyOrder) {
            targetOrders = buyOrdersUSDT; // Insert into buy orders list

            // Check if the array has 20 or more orders
            if (targetOrders.length >= 20) {
                // Remove the worst-priced order and refund the owner
                removeWorstPricedOrder(targetOrders, SharedStructs.PaymentMethod.USDT);
            }
        } else {
            targetOrders = sellOrdersUSDT; // Insert into sell orders list

            // Check if the array has 20 or more orders
            if (targetOrders.length >= 20) {
                // Remove the worst-priced sell order and refund the owner
                removeWorstPricedSellOrder(targetOrders, newOrder.assetType);
            }
        }

        // Insert the new order at the top of the list (since it has the best price)
        targetOrders.push(newOrder); // Temporarily increase the array size
        for (uint256 i = targetOrders.length - 1; i > 0; i--) {
            targetOrders[i] = targetOrders[i - 1]; // Shift orders down
        }
        targetOrders[0] = newOrder; // Place the new order at the top
    }
}*/


    function executeTradeUSDT(SharedStructs.Order memory newOrder, SharedStructs.Order storage oppositeOrder, uint256 tradeAmount, bool isBuyOrder) internal {
    address payable buyer;
    address payable seller;
    uint256 price;

    if (isBuyOrder) {
        // For buy orders: buyer is the new order user, seller is the opposite order user
        buyer = newOrder.user;
        seller = oppositeOrder.user;
        price = newOrder.price;
    } else {
        // For sell orders: buyer is the opposite order user, seller is the new order user
        buyer = oppositeOrder.user;
        seller = newOrder.user;
        price = oppositeOrder.price;
    }

    // Calculate the payment amount
    uint256 paymentAmount = (tradeAmount * price) / 1000;

    // Deduct payment from buyer
    escrowHandler.updateEscrowBalance(buyer, newOrder.priceCurrency, paymentAmount, false);

    // Check seller's escrowed Nickelium
    require(
        escrowHandler.getAssetBalance(seller, SharedStructs.AssetType.Nickelium) >= tradeAmount,
        "Seller does not have enough Nickelium in escrow"
    );

    // Transfer Nickelium from escrow to buyer
    nickeliumContract.approveToken(address(nickeliumContract), address(escrowHandler), tradeAmount);
    escrowHandler.transferFromAsset(seller, buyer, tradeAmount);

    // Transfer USDT payment to the seller
    escrowHandler.approveUSDT(paymentAmount);
    USDTContract.transferFrom(address(escrowHandler), seller, paymentAmount);
}

    function removeOrderFromList(SharedStructs.Order[] storage orders, uint256 index) internal {
    require(index < orders.length, "Index out of bounds");

    // Shift all orders below the removed order up by one position
    for (uint256 i = index; i < orders.length - 1; i++) {
        orders[i] = orders[i + 1];
    }

    // Remove the last order
    orders.pop();
}

    function insertOrderInSortedPosition(
    SharedStructs.Order[] storage orders,
    SharedStructs.Order memory newOrder
) internal {
    uint256 n = orders.length;
    uint256 i = 0;

    // Find the correct insertion index (Descending Order)
    while (i < n && orders[i].price >= newOrder.price) {
        i++;
    }

    // Handle 20-order cap
    if (n >= 20) {
        SharedStructs.Order memory lastOrder = orders[n - 1];
        // If the new order is priced higher than the lowest-priced order, remove the last one
        if (newOrder.price > lastOrder.price) {
            removeWorstPricedOrder(orders, newOrder.priceCurrency);
            n = orders.length; // n is now 19
            // Adjust insertIndex if it exceeds the new length
            if (i > n) {
                i = n;
            }
        } else {
            // If the new order is not better than the worst, do not insert
            revert("New order price is not high enough to be inserted.");
        }
    }

    // Expand array by pushing a dummy value
    orders.push(newOrder); // Increase length by 1
    // Shift elements from the end down to the insertion index
    for (uint256 j = orders.length - 1; j > i; j--) {
        orders[j] = orders[j - 1];
    }
    // Insert the new order at the correct position
    orders[i] = newOrder;
}

    function insertSellOrderInSortedPosition(
    SharedStructs.Order[] storage orders,
    SharedStructs.Order memory newOrder
) internal {
    uint256 n = orders.length;
    uint256 i = 0;

    // Find the correct insertion index for sell orders (ascending order).
    // We want orders with lower prices first.
    // For equal prices, we move past the existing ones.
    while (i < n && orders[i].price <= newOrder.price) {
        i++;
    }
    
    // Handle the 20-order cap.
    if (n >= 20) {
        SharedStructs.Order memory lastOrder = orders[n - 1];
        // For sell orders, the worst (highest-priced) order is at the bottom.
        // If the new order is priced lower than the worst, it deserves insertion.
        if (newOrder.price < lastOrder.price) {
            removeWorstPricedSellOrder(orders, newOrder.assetType);
            n = orders.length; // Now n is reduced (likely 19).
            // Adjust insertIndex if needed.
            if (i > n) {
                i = n;
            }
        } else {
            // If the new order is not better than the worst, do not insert it.
            revert("New order price is not low enough to be inserted.");
        }
    }
    
    // Expand the array by pushing a dummy element (here, newOrder is used as a placeholder).
    orders.push(newOrder);
    // Shift elements from the end down to the insertion index.
    for (uint256 j = orders.length - 1; j > i; j--) {
        orders[j] = orders[j - 1];
    }
    // Place the new order at the correct position.
    orders[i] = newOrder;
}

function removeWorstPricedOrder(SharedStructs.Order[] storage orders, SharedStructs.PaymentMethod paymentMethod) internal {
    // Get the last (worst-priced) order in the list
    uint256 lastIndex = orders.length - 1;
    SharedStructs.Order memory worstOrder = orders[lastIndex];

    // Remove the order from the list
    orders.pop();

    // Calculate the remaining amount (no need for fulfilledAmount)
    uint256 remainingAmount = worstOrder.amount;

    // Calculate the cost to refund
    uint256 cost = (worstOrder.price * remainingAmount) / 1000;

    // Refund the escrowed funds to the owner of the worst-priced order
    
        escrowHandler.approveUSDT(cost);
        USDTContract.transferFrom(address(escrowHandler), worstOrder.user, cost);
        escrowHandler.updateEscrowBalance(worstOrder.user, paymentMethod, cost, false);
   
}

    function removeWorstPricedSellOrder(SharedStructs.Order[] storage orders, SharedStructs.AssetType assetType) internal {
    // Get the last (worst-priced) sell order in the list
    uint256 lastIndex = orders.length - 1;
    SharedStructs.Order memory worstOrder = orders[lastIndex];
    address orderOwner = worstOrder.user;

    // Remove the order from the list
    orders.pop();

    // Calculate the remaining amount
    uint256 remainingAmount = worstOrder.amount;

    // Get the asset escrow balance of the order owner
    uint256 assetEscrowBalance = escrowHandler.getAssetBalance(orderOwner, assetType);

    // Calculate the amount to transfer (cannot exceed the escrow balance)
    uint256 assetTransferAmount = assetEscrowBalance < remainingAmount ? assetEscrowBalance : remainingAmount;

    // Ensure there is enough escrowed balance to refund
    require(assetEscrowBalance >= assetTransferAmount, "Insufficient token escrow balance");

    // Transfer the asset back to the owner
    nickeliumContract.transferFromContract(orderOwner, assetTransferAmount);

    // Update the asset escrow balance
    escrowHandler.setAssetBalance(orderOwner, assetType, assetEscrowBalance - assetTransferAmount);
}

    function addSellOrder(uint256 _orderID, address seller, uint256 _price, uint256 _amount, SharedStructs.AssetType _assetType, SharedStructs.PaymentMethod _priceCurrency, bool authorizedBuyersOnly) external onlyAuthorized whenNotPaused {
    // Update the asset balance in escrow
    uint256 currentBalance = escrowHandler.getAssetBalance(seller, _assetType);
    escrowHandler.setAssetBalance(seller, _assetType, currentBalance + _amount);
    
    SharedStructs.Order memory newOrder = SharedStructs.Order({
        orderID: _orderID,
        user: payable(seller),
        price: _price,
        amount: _amount,
        fulfilledAmount: 0,
        assetType: _assetType,
        priceCurrency: _priceCurrency,
        authorizedBuyersOnly: authorizedBuyersOnly
    });
    require(_price >= centralContract.LMEprice(), "Order price must be at least the current LME price");
        if (sellOrdersUSDT.length == 0) {
    // If the sellOrdersUSDT array is empty, execute matching logic with opposite orders (buyOrdersUSDT)
    matchNewOrderUSDT(newOrder, false, true); // false for sell order
} else {
    // If the sellOrdersUSDT array is not empty, check if the new order's price is higher than the first buy order's price
    if (newOrder.price < sellOrdersUSDT[0].price) {
        // Execute matching logic
        matchNewOrderUSDT(newOrder, false, true); // false for sell order
    } else {
        // Insert the new order into the correct position
        insertSellOrderInSortedPosition(sellOrdersUSDT, newOrder); // true for buy order
    }
}
}
     function repositionOrder(
    SharedStructs.Order[] storage orders,
    uint256 index,
    bool isAscending // true for sell orders (ascending), false for buy orders (descending)
) internal {
    require(index < orders.length, "Index out of bounds");

    // Copy the order that needs repositioning.
    SharedStructs.Order memory updatedOrder = orders[index];
    bool orderPlaced = false;

    if (isAscending) {
        // For sell orders (ascending): lower prices come first.
        // Move upward if the updated order's price is lower than the order above.
        for (uint256 i = index; i > 0 && updatedOrder.price < orders[i - 1].price; i--) {
            orders[i] = orders[i - 1];
            index = i - 1;
        }

        // Move downward if the updated order's price is higher than the order below.
        for (uint256 i = index; i < orders.length - 1 && updatedOrder.price > orders[i + 1].price; i++) {
            if (!orderPlaced) {
                orders[i] = orders[i + 1];
                index = i + 1;
            }
        }

        // Ensure updated order is placed after any existing orders with the same price.
        for (uint256 i = index; i < orders.length - 1 && updatedOrder.price == orders[i + 1].price; i++) {
            if (!orderPlaced) {
                orders[i] = orders[i + 1];
                index = i + 1;
            }
        }

    } else {
        // For buy orders (descending): higher prices come first.
        // Move upward if the updated order's price is higher than the order above.
        for (uint256 i = index; i > 0 && updatedOrder.price > orders[i - 1].price; i--) {
            orders[i] = orders[i - 1];
            index = i - 1;
        }

        // Move downward if the updated order's price is lower than the order below.
        for (uint256 i = index; i < orders.length - 1 && updatedOrder.price < orders[i + 1].price; i++) {
            if (!orderPlaced) {
                orders[i] = orders[i + 1];
                index = i + 1;
            }
        }

        // Ensure updated order is placed after any existing orders with the same price.
        for (uint256 i = index; i < orders.length - 1 && updatedOrder.price == orders[i + 1].price; i++) {
            if (!orderPlaced) {
                orders[i] = orders[i + 1];
                index = i + 1;
            }
        }
    }

    // Finally, place the updated order at position index if not already placed.
    if (!orderPlaced) {
        orders[index] = updatedOrder;
    }
}

    /*function repositionOrder(
    SharedStructs.Order[] storage orders,
    uint256 index,
    bool isBuyOrder
) internal {
    require(index < orders.length, "Index out of bounds");

    SharedStructs.Order memory updatedOrder = orders[index];
    uint256 newIndex = findInsertPosition(orders, updatedOrder.price, isBuyOrder);

    if (newIndex == index) return; // No movement needed

    // Save the order and determine shift direction
    SharedStructs.Order memory orderToMove = orders[index];
    if (newIndex < index) {
        // Shift orders[newIndex..index-1] right by 1
        for (uint256 i = index; i > newIndex; i--) {
            orders[i] = orders[i - 1];
        }
    } else {
        // Shift orders[index+1..newIndex] left by 1
        for (uint256 i = index; i < newIndex; i++) {
            orders[i] = orders[i + 1];
        }
    }

    // Place the order at the new index
    orders[newIndex] = orderToMove;
}*/

function findInsertPosition(
    SharedStructs.Order[] storage orders,
    uint256 price,
    bool isBuyOrder
) internal view returns (uint256) {
    uint256 insertIndex = 0;
    uint256 n = orders.length;

    // For buy orders (descending), stop at first order with price < new price
    if (isBuyOrder) {
        while (insertIndex < n && orders[insertIndex].price >= price) {
            insertIndex++;
        }
    }
    // For sell orders (ascending), stop at first order with price > new price
    else {
        while (insertIndex < n && orders[insertIndex].price <= price) {
            insertIndex++;
        }
    }

    return insertIndex;
}
    
    /*function repositionOrder(SharedStructs.Order[] storage orders, uint256 index, bool isAscending) internal {
    if (orders.length <= 1) return;

    SharedStructs.Order memory updatedOrder = orders[index];
    uint256 newIndex = findInsertPosition(orders, updatedOrder.price, isAscending);

    if (newIndex == index) return; // No need to move

    if (newIndex < index) {
        // Move order to new position and shift others right
        for (uint256 i = index; i > newIndex; i--) {
            orders[i] = orders[i - 1];
        }
    } else {
        // Move order to new position and shift others left
        for (uint256 i = index; i < newIndex; i++) {
            orders[i] = orders[i + 1];
        }
    }

    orders[newIndex] = updatedOrder;
}

function findInsertPosition(SharedStructs.Order[] storage orders, uint256 price, bool isAscending) internal view returns (uint256) {
    uint256 left = 0;
    uint256 right = orders.length;
    while (left < right) {
        uint256 mid = left + (right - left) / 2;
        if (isAscending ? price < orders[mid].price : price > orders[mid].price) {
            right = mid;
        } else {
            left = mid + 1;
        }
    }
    return left;
}*/
   /*function repositionOrder(SharedStructs.Order[] storage orders, uint256 index, bool isAscending) internal {
    if (orders.length <= 1) return; // No need to reposition if only one order

    // Step 1: Extract the order and remove it from its current position
    SharedStructs.Order memory updatedOrder = orders[index];
    for (uint256 i = index; i < orders.length - 1; i++) {
        orders[i] = orders[i + 1]; // Shift left
    }
    orders.pop(); // Reduce array size

    // Step 2: Find the correct position using Binary Search (O(log N))
    uint256 left = 0;
    uint256 right = orders.length;
    while (left < right) {
        uint256 mid = left + (right - left) / 2;
        if (isAscending ? updatedOrder.price < orders[mid].price : updatedOrder.price > orders[mid].price) {
            right = mid;
        } else {
            left = mid + 1;
        }
    }

    // Step 3: Insert at the correct position (O(N) worst case)
    orders.push(); // Increase array size
    for (uint256 j = orders.length - 1; j > left; j--) {
        orders[j] = orders[j - 1]; // Shift right
    }
    orders[left] = updatedOrder; // Insert order at correct position
}*/

    function changeBuyOrderPriceUSDT(address buyer, uint256 orderID, uint256 newPrice) external onlyAuthorized nonReentrant whenNotPaused {
    require(newPrice >= centralContract.LMEprice(), "Order price must be at least the current LME price");
    for (uint256 i = 0; i < buyOrdersUSDT.length; i++) {
        if (buyOrdersUSDT[i].orderID == orderID) {
            SharedStructs.Order storage order = buyOrdersUSDT[i];
            require(order.user == buyer, "Only the owner can change the price");

            uint256 remainingAmount = order.amount;
            uint256 oldCost = (order.price * remainingAmount) / 1000;
            uint256 newCost = (newPrice * remainingAmount) / 1000;

            if (newCost > oldCost) {
                uint256 additionalCost = newCost - oldCost;
                escrowHandler.updateEscrowBalance(order.user, SharedStructs.PaymentMethod.USDT, additionalCost, true);
            } else {
                uint256 refund = oldCost - newCost;
                uint256 currentEscrowBalance = escrowHandler.getEscrowBalance(order.user, SharedStructs.PaymentMethod.USDT);
                require(currentEscrowBalance >= refund, "Insufficient escrow balance for refund");
                escrowHandler.approveUSDT(refund);
                USDTContract.transferFrom(address(escrowHandler), order.user, refund);
                escrowHandler.updateEscrowBalance(order.user, SharedStructs.PaymentMethod.USDT, refund, false);
            }

           // Update the price of the order
                order.price = newPrice;

                // Store order details in memory before repositioning
                SharedStructs.Order memory updatedOrder = order;

            // Reposition the order
            repositionOrder(buyOrdersUSDT, i, false); // false for descending order

            // Match orders only if the new price is >= best available sell order price
            if (sellOrdersUSDT.length > 0 && newPrice >= sellOrdersUSDT[0].price) {
                matchNewOrderUSDT(updatedOrder, true, false); // Call match function
            }

            return;
        }
    }
    revert("Order not found");
}

    function changeSellOrderPriceUSDT(address seller, uint256 orderID, uint256 newPrice) external onlyAuthorized nonReentrant whenNotPaused {
    require(newPrice >= centralContract.LMEprice(), "Order price must be at least the current LME price");
    for (uint256 i = 0; i < sellOrdersUSDT.length; i++) {
        if (sellOrdersUSDT[i].orderID == orderID) {
            SharedStructs.Order storage order = sellOrdersUSDT[i];
            require(order.user == seller, "Only the owner can change the price");

             // Update the price of the order
            order.price = newPrice;

             // Store order details in memory before repositioning
            SharedStructs.Order memory updatedOrder = order;

            // Reposition the order (ascending order for sell orders)
            repositionOrder(sellOrdersUSDT, i, true);

            // Match orders only if the new price is <= best available buy order price
            if (buyOrdersUSDT.length > 0 && newPrice <= buyOrdersUSDT[0].price) {
                matchNewOrderUSDT(updatedOrder, false, false); // Call match function
            }

            return;
        }
    }
    revert("Order not found");
}

    function pause() external onlyAuthorized nonReentrant whenNotPaused {
        _pause();
    }

    function unpause() external onlyAuthorized nonReentrant {
        _unpause();
    }


}