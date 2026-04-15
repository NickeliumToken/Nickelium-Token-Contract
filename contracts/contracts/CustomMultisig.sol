// SPDX-License-Identifier: Custom-License
/*This contract is part of Nickelium Token Ecosystem and is property of Destrier LLC. You are granted permission to use all functions of this contract intended for users. 
*However, copying, modifying, or distributing the code is strictly prohibited without explicit permission from the author.
*All rights reserved. Destrier LLC, registration number 20241316871 , Colorado , USA.*/

pragma solidity ^0.8.0;

interface INFTContract {
    // Existing function
    function upgradeNFT(string memory name) external payable;

    // New functions
    function increaseUsedStock(uint256 amount) external;
    function setStockLimit(uint256 newLimit) external;
}

import "./SharedStructs.sol";
import "./IEscrowHandler.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "./INickelium.sol";
import "./IAdminControl.sol";
import "@openzeppelin/contracts/utils/Pausable.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import "./ICentral.sol";
import "./IOrderRouter.sol";
import "./ITether.sol";

contract CustomMultisig is Pausable, ReentrancyGuard {
    address public owner1;
    address public owner2;
    bool public isConfirmedByOwner1;
    bool public isConfirmedByOwner2;
     ITether public USDTContract;
     IERC20 public USDCContract;
     INickelium public nickelium;
    INickelium public nickeliumContract;
    IEscrowHandler public escrowHandler;
    IAdminControl public adminControlContract;
    ICentral public centralContract;
    IOrderRouter public orderRouter;

    INFTContract public mine1NFT;
    INFTContract public mine2NFT;
    INFTContract public mine3NFT;
    INFTContract public mine4NFT;
    INFTContract public mine5NFT;

    
    uint256 public defaultIndex = 0;
    uint256 public nextTransferId = 0;

    // Import AssetType and PaymentMethod from SharedStructs
    using SharedStructs for SharedStructs.AssetType;
    using SharedStructs for SharedStructs.PaymentMethod;

    /*address public owner;
    function setOwner(address newOwner) public onlyAuthorized {
        owner = newOwner;
    }*/

    // Store pending order details
    struct PendingOrder {
        uint256 orderID;
        address payable user;
        uint256 price;
        uint256 amount;
        SharedStructs.AssetType assetType;
        SharedStructs.PaymentMethod priceCurrency;
        bool isConfirmedByOwner1;
        bool isConfirmedByOwner2;
        string orderType;
        bool authorizedBuyersOnly;
    }

   struct TransferStatus {
        bool isConfirmedByOwner1;
        bool isConfirmedByOwner2;
        uint256 amount;
        address recipientAddress;
        SharedStructs.PaymentMethod paymentMethod;
        uint256 transferID;
    }

    struct TransferStatusNickelium {
        bool isConfirmedByOwner1;
        bool isConfirmedByOwner2;
        uint256 amount;
        address recipientAddress;
        SharedStructs.AssetType assetType;
        uint256 transferID;
    }

    mapping(uint256 => PendingOrder) public pendingOrders;
    mapping(uint256 => TransferStatus) public transferStatus;
    mapping(uint256 => TransferStatusNickelium) public transferStatusNickelium;
    uint256[] public indexes; // Auxiliary array to store order IDs
    mapping(address => bool) public authorizedAddresses;
    mapping(address => bool) public payerAddresses;

    constructor() {
               authorizedAddresses[msg.sender] = true;
    }
function setOwners(address _owner1, address _owner2) external onlyAuthorized nonReentrant whenNotPaused{
        owner1 = _owner1;
        owner2 = _owner2;
    }

    modifier onlyAuthorized() {
        require(authorizedAddresses[msg.sender], "Not authorized");
        _;
    }

    modifier onlyPayer() {
        require(payerAddresses[msg.sender], "Not a payer");
        _;
    }

    function setAuthorizedAddress(address _address, bool _status) public onlyAuthorized nonReentrant whenNotPaused{
        authorizedAddresses[_address] = _status;
    }

    function setPayerAddress(address _address, bool _status) public onlyAuthorized nonReentrant whenNotPaused{
        payerAddresses[_address] = _status;
    }

    function setContracts(
        address _mine1NFTAddress, address _mine2NFTAddress, address _mine3NFTAddress, address _mine4NFTAddress, address _mine5NFTAddress,
        address payable _nickeliumAddress,
        address _centralAddress,
        address _USDTAddress,
        address _usdcAddress,
        address _escrowHandler,
        address _adminControlAddress,
        address _orderRouterAddress
    ) external onlyAuthorized nonReentrant whenNotPaused {
        // Set Nickelium and its interface
        nickeliumContract = INickelium(_nickeliumAddress);
        nickelium = INickelium(_nickeliumAddress);

        centralContract = ICentral(_centralAddress);

        // Set USDTContract
        USDTContract = ITether(_USDTAddress);

        // Set USDCContract and address
    USDCContract = IERC20(_usdcAddress); 

        // Set EscrowHandler
        escrowHandler = IEscrowHandler(_escrowHandler);

        // Set AdminControl
        adminControlContract = IAdminControl(_adminControlAddress);
        orderRouter = IOrderRouter(_orderRouterAddress);
        mine1NFT = INFTContract(_mine1NFTAddress);
        mine2NFT = INFTContract(_mine2NFTAddress);
        mine3NFT = INFTContract(_mine3NFTAddress);
        mine4NFT = INFTContract(_mine4NFTAddress);
        mine5NFT = INFTContract(_mine5NFTAddress);
    }
    
// Fallback function to handle incoming Ether
    fallback() external payable {
        // Log an event or update state as needed
        emit EtherReceived(msg.sender, msg.value);
    }
    event EtherReceived(address indexed sender, uint256 amount);
    
    modifier onlyOwners() {
        require(msg.sender == owner1 || msg.sender == owner2, "Not an owner");
        _;
    }

    function transferEtherToCentral(uint256 amount) internal {
        //require(msg.sender == owner1 || msg.sender == owner2, "Unauthorized");
        require(address(this).balance >= amount, "Insufficient contract balance");
        //nickeliumContract.transfer(address(this), amount);
        payable(address(centralContract)).transfer(amount);
    }
    
   
     function CreateBuyOrderEther (
        uint256 _price,
        uint256 _amount
        
    ) external onlyOwners nonReentrant whenNotPaused {
        require(_price * _amount / _price == _amount, "Potential overflow");
        // Create a pending order
        // Get the next order ID from the Nickelium contract
        uint256 _orderID = centralContract.getNextOrderID();
        //uint256 index = indexes.length; // Use the array length as the order ID
        pendingOrders[_orderID] = PendingOrder({
            orderID: _orderID,
            user: payable(address(this)),
           // owner: payable(msg.sender),
            price: _price,
            amount: _amount,
            assetType: SharedStructs.AssetType.Nickelium, 
            priceCurrency: SharedStructs.PaymentMethod.Ether,
            isConfirmedByOwner1: false,
            isConfirmedByOwner2: false,
            orderType: "Buy",
            authorizedBuyersOnly: false
        });
        indexes.push(_orderID); // Add the order ID to the auxiliary array
    }
    function CreateBuyOrderUSDT(
        uint256 _price,
        uint256 _amount
         
     ) external onlyOwners nonReentrant whenNotPaused {
        require(_price * _amount / _price == _amount, "Potential overflow");
         // Create a pending order
         // Get the next order ID from the Nickelium contract
        uint256 _orderID = centralContract.getNextOrderID();
         //*uint256 index = indexes.length; // Use the array length as the order ID*/
        pendingOrders[_orderID] = PendingOrder({
            orderID: _orderID,
            user: payable(address(this)),
           // owner: payable(msg.sender),
            price: _price,
            amount: _amount,
            assetType: SharedStructs.AssetType.Nickelium, 
            priceCurrency: SharedStructs.PaymentMethod.USDT,
            isConfirmedByOwner1: false,
            isConfirmedByOwner2: false,
            orderType: "Buy",
            authorizedBuyersOnly: false
         });
        indexes.push(_orderID); // Add the order ID to the auxiliary array
     }

     function CreateBuyOrderUSDC(
        uint256 _price,
        uint256 _amount
         
     ) external onlyOwners nonReentrant whenNotPaused {
        require(_price * _amount / _price == _amount, "Potential overflow");
         // Create a pending order
         // Get the next order ID from the Nickelium contract
        uint256 _orderID = centralContract.getNextOrderID();
         //*uint256 index = indexes.length; // Use the array length as the order ID*/
        pendingOrders[_orderID] = PendingOrder({
            orderID: _orderID,
            user: payable(address(this)),
           // owner: payable(msg.sender),
            price: _price,
            amount: _amount,
            assetType: SharedStructs.AssetType.Nickelium, 
            priceCurrency: SharedStructs.PaymentMethod.USDC,
            isConfirmedByOwner1: false,
            isConfirmedByOwner2: false,
            orderType: "Buy",
            authorizedBuyersOnly: false
         });
        indexes.push(_orderID); // Add the order ID to the auxiliary array
     }

    function CreateSellOrderEther(
        uint256 _price,
        uint256 _amount,
        bool _authorizedBuyersOnly
        
    ) external onlyOwners nonReentrant whenNotPaused {
        require(_price * _amount / _price == _amount, "Potential overflow");
        // Create a pending order
        // Get the next order ID from the Nickelium contract
        uint256 _orderID = centralContract.getNextOrderID();
        //uint256 index = indexes.length; // Use the array length as the order ID
        pendingOrders[_orderID] = PendingOrder({
            orderID: _orderID,
            user: payable(address(this)),
         //   owner: payable(msg.sender),
            price: _price,
            amount: _amount,
            assetType: SharedStructs.AssetType.Nickelium, 
            priceCurrency: SharedStructs.PaymentMethod.Ether,
            isConfirmedByOwner1: false,
            isConfirmedByOwner2: false,
            orderType: "Sell",
            authorizedBuyersOnly: _authorizedBuyersOnly 
        });
        indexes.push(_orderID); // Add the order ID to the auxiliary array
    }

    function CreateSellOrderUSDT(
        uint256 _price,
        uint256 _amount,
        bool _authorizedBuyersOnly
        
    ) external onlyOwners nonReentrant whenNotPaused {
        require(_price * _amount / _price == _amount, "Potential overflow");
        // Create a pending order
        // Get the next order ID from the Nickelium contract
        uint256 _orderID = centralContract.getNextOrderID();
        //uint256 index = indexes.length; // Use the array length as the order ID
        pendingOrders[_orderID] = PendingOrder({
            orderID: _orderID,
            user: payable(address(this)),
         //   owner: payable(msg.sender),
            price: _price,
            amount: _amount,
            assetType: SharedStructs.AssetType.Nickelium, 
            priceCurrency: SharedStructs.PaymentMethod.USDT,
            //assetType: _assetType,
            //priceCurrency: _priceCurrency,
            isConfirmedByOwner1: false,
            isConfirmedByOwner2: false,
            orderType: "Sell",
            authorizedBuyersOnly: _authorizedBuyersOnly
        });
        indexes.push(_orderID); 
    }

    function CreateSellOrderUSDC(
        uint256 _price,
        uint256 _amount,
        bool _authorizedBuyersOnly
        
    ) external onlyOwners nonReentrant whenNotPaused {
        require(_price * _amount / _price == _amount, "Potential overflow");
        // Create a pending order
        // Get the next order ID from the Nickelium contract
        uint256 _orderID = centralContract.getNextOrderID();
        //uint256 index = indexes.length; // Use the array length as the order ID
        pendingOrders[_orderID] = PendingOrder({
            orderID: _orderID,
            user: payable(address(this)),
         //   owner: payable(msg.sender),
            price: _price,
            amount: _amount,
            assetType: SharedStructs.AssetType.Nickelium, 
            priceCurrency: SharedStructs.PaymentMethod.USDC,
            isConfirmedByOwner1: false,
            isConfirmedByOwner2: false,
            orderType: "Sell",
            authorizedBuyersOnly: _authorizedBuyersOnly
        });
        indexes.push(_orderID); // Add the order ID to the auxiliary array
    }

    
    function confirmOrder(uint256 _orderID) external onlyOwners nonReentrant whenNotPaused {
    PendingOrder storage order = pendingOrders[_orderID];
    if (msg.sender == owner1) {
        order.isConfirmedByOwner1 = true;
    } else if (msg.sender == owner2) {
        order.isConfirmedByOwner2 = true;
    }
}
    
function confirmTransfer(uint256 _transferID) external onlyOwners nonReentrant whenNotPaused {
   
    // Check which mapping actually contains this order by looking for a valid recipient
    if (transferStatus[_transferID].recipientAddress != address(0)) {
        TransferStatus storage order = transferStatus[_transferID];
        if (msg.sender == owner1) {
            require(!order.isConfirmedByOwner1, "Already confirmed by this owner");
            order.isConfirmedByOwner1 = true;
        } else if (msg.sender == owner2) {
            require(!order.isConfirmedByOwner2, "Already confirmed by this owner");
            order.isConfirmedByOwner2 = true;
        }
    } else if (transferStatusNickelium[_transferID].recipientAddress != address(0)) {
        TransferStatusNickelium storage order = transferStatusNickelium[_transferID];
        if (msg.sender == owner1) {
            require(!order.isConfirmedByOwner1, "Already confirmed by this owner");
            order.isConfirmedByOwner1 = true;
        } else if (msg.sender == owner2) {
            require(!order.isConfirmedByOwner2, "Already confirmed by this owner");
            order.isConfirmedByOwner2 = true;
        }
    } else {
        revert("Transfer ID not found in any transfer list");
    }
}


   function CancelConfirmTransfer(uint256 _transferID) external onlyOwners nonReentrant whenNotPaused {
    // Check which mapping actually contains this order
    if (transferStatus[_transferID].recipientAddress != address(0)) {
        TransferStatus storage order = transferStatus[_transferID];
        if (msg.sender == owner1) {
            order.isConfirmedByOwner1 = false;
        } else if (msg.sender == owner2) {
            order.isConfirmedByOwner2 = false;
        }
    } else if (transferStatusNickelium[_transferID].recipientAddress != address(0)) {
        TransferStatusNickelium storage order = transferStatusNickelium[_transferID];
        if (msg.sender == owner1) {
            order.isConfirmedByOwner1 = false;
        } else if (msg.sender == owner2) {
            order.isConfirmedByOwner2 = false;
        }
    } else {
        revert("Transfer ID not found");
    }
}

    
    function createTransferEther(
    address _recipientAddress,
    uint256 _amount
) public onlyOwners nonReentrant whenNotPaused {
    uint256 transferID = nextTransferId;
    transferStatus[transferID] = TransferStatus(
        false, // isConfirmedByOwner1
        false, // isConfirmedByOwner2
        _amount,
        _recipientAddress,
        SharedStructs.PaymentMethod.Ether, // Payment method for Ether
        transferID
    );
    indexes.push(transferID);
    nextTransferId++;
}

    function createTransferUSDT(
    address _recipientAddress,
    uint256 _amount
) public onlyOwners nonReentrant whenNotPaused {
    uint256 transferID = nextTransferId;
    transferStatus[transferID] = TransferStatus(
        false, // isConfirmedByOwner1
        false, // isConfirmedByOwner2
        _amount,
        _recipientAddress,
        SharedStructs.PaymentMethod.USDT, // Payment method for USDT
        transferID
    );
    indexes.push(transferID);
    nextTransferId++;
}

function createTransferUSDC(
    address _recipientAddress,
    uint256 _amount
) public onlyOwners nonReentrant whenNotPaused {
    uint256 transferID = nextTransferId;
    transferStatus[transferID] = TransferStatus(
        false, // isConfirmedByOwner1
        false, // isConfirmedByOwner2
        _amount,
        _recipientAddress,
        SharedStructs.PaymentMethod.USDC, // Payment method for USDC
        transferID
    );
    indexes.push(transferID);
    nextTransferId++;
}

function createTransferNickelium(
    address _recipientAddress,
    uint256 _amount
) public onlyOwners nonReentrant whenNotPaused {
    uint256 transferID = nextTransferId;
    transferStatusNickelium[transferID] = TransferStatusNickelium(
        false, // isConfirmedByOwner1
        false, // isConfirmedByOwner2
        _amount,
        _recipientAddress,
        SharedStructs.AssetType.Nickelium, // Only for Nickelium transfers
        transferID
    );
    indexes.push(transferID);
    nextTransferId++;
}

    function executeTransfer(uint256 _transferID) public onlyOwners nonReentrant whenNotPaused {
    // Check for a payment transfer in transferStatus
    if (transferStatus[_transferID].recipientAddress != address(0)) { // Check if the orderID exists
        TransferStatus storage transfer = transferStatus[_transferID];
        require(transfer.isConfirmedByOwner1 && transfer.isConfirmedByOwner2, "Both confirmations required");

        if (transfer.paymentMethod == SharedStructs.PaymentMethod.Ether) {
            // Handle Ether transfer
            require(address(this).balance >= transfer.amount, "Insufficient Ether balance");
            payable(transfer.recipientAddress).transfer(transfer.amount);

        } else if (transfer.paymentMethod == SharedStructs.PaymentMethod.USDT) {
            // Handle USDT transfer
            require(USDTContract.balanceOf(address(this)) >= transfer.amount, "Insufficient USDT balance");
            //require(USDTContract.transfer(transfer.recipientAddress, transfer.amount), "USDT transfer failed");
            USDTContract.transfer(transfer.recipientAddress, transfer.amount);

        } else if (transfer.paymentMethod == SharedStructs.PaymentMethod.USDC) {
            // Handle USDC transfer
            require(USDCContract.balanceOf(address(this)) >= transfer.amount, "Insufficient USDC balance");
            require(USDCContract.transfer(transfer.recipientAddress, transfer.amount), "USDC transfer failed");
        }

        // Delete the order after successful execution
        delete transferStatus[_transferID];
		 _removeTransferId(_transferID); 
    } else {
        // Now check for Nickelium transfers in transferStatusNickelium
        TransferStatusNickelium storage nickeliumTransfer = transferStatusNickelium[_transferID];
        require(nickeliumTransfer.recipientAddress != address(0), "No Nickelium transfer with this orderID"); // Check if it exists
        require(nickeliumTransfer.isConfirmedByOwner1 && nickeliumTransfer.isConfirmedByOwner2, "Both confirmations required");
        require(nickeliumContract.balanceOf(address(this)) >= nickeliumTransfer.amount, "Insufficient Nickelium balance");
        require(nickeliumContract.transfer(nickeliumTransfer.recipientAddress, nickeliumTransfer.amount), "Nickelium transfer failed");

        // Delete the order after successful execution
        delete transferStatusNickelium[_transferID];
		 _removeTransferId(_transferID); 
    }
}

     
   function DisplayAllTransfers() external view returns (TransferStatus[] memory, TransferStatusNickelium[] memory) {
    uint256[] storage storageIndexes = indexes;
    
    TransferStatus[] memory allTransfers = new TransferStatus[](storageIndexes.length);
    TransferStatusNickelium[] memory allTransfersNickelium = new TransferStatusNickelium[](storageIndexes.length);
    
    for (uint256 i = 0; i < storageIndexes.length; i++) {
        uint256 transferID = storageIndexes[i];
        
        // Check the recipientAddress to see which mapping has the valid data
        if (transferStatus[transferID].recipientAddress != address(0)) {
            allTransfers[i] = transferStatus[transferID];
        } else if (transferStatusNickelium[transferID].recipientAddress != address(0)) {
            allTransfersNickelium[i] = transferStatusNickelium[transferID];
        }
        // If both are address(0), both arrays will have a default struct at index i
    }
    return (allTransfers, allTransfersNickelium);
}

   function _removeTransferId(uint256 _orderID) internal {
    uint256 indexToDelete = 0;
    bool found = false;

    // Find the index of the orderID in the array
    for (uint256 i = 0; i < indexes.length; i++) {
        if (indexes[i] == _orderID) {
            indexToDelete = i;
            found = true;
            break;
        }
    }
    require(found, "Order not found in the list");

    // Remove the element by shifting and popping
    for (uint256 i = indexToDelete; i < indexes.length - 1; i++) {
        indexes[i] = indexes[i + 1];
    }
    indexes.pop();
}


    function deleteTransfer(uint256 _transferID) public onlyOwners whenNotPaused {
    
    // Delete the data from the mappings
    delete transferStatus[_transferID];
    delete transferStatusNickelium[_transferID];

    // Remove the ID from the index array
    _removeTransferId(_transferID);
}


    function cancelConfirmOrder(uint256 _orderID) external onlyOwners nonReentrant whenNotPaused {
        PendingOrder storage order = pendingOrders[_orderID];
    if (msg.sender == owner1) {
               order.isConfirmedByOwner1 = false;
    } else if (msg.sender == owner2) {
              order.isConfirmedByOwner2 = false;
    }
}
       function executeOrder(uint256 _orderID) external payable onlyOwners nonReentrant whenNotPaused {
        PendingOrder storage order = pendingOrders[_orderID];
        require(order.isConfirmedByOwner1 && order.isConfirmedByOwner2, "Both parties must confirm");

        if (keccak256(bytes(order.orderType)) == keccak256("Buy")) {
            executeBuyOrder(_orderID);
        } else if (keccak256(bytes(order.orderType)) == keccak256("Sell")) {
            executeSellOrder(_orderID);
        }
    }

 function executeBuyOrder(uint256 _orderID) internal {
        PendingOrder storage order = pendingOrders[_orderID];
        require(order.isConfirmedByOwner1 == true && order.isConfirmedByOwner2 == true, "Both parties must confirm");
                // Retrieve the amount from the order
    uint256 _amount = order.amount;
    uint256 _price = order.price;
    //require(nickeliumContract.balanceOf(address(this)) >= _amount, "Insufficient balance for the operation");
    require(order.price > 0, "This order is not exist");
    address buyer = payable (address(this)); // Capture user address
   // require(msg.value >= _price * _amount, "Insufficient Ether for buy order");
    uint256 cost = (_price * _amount) / 1000;
if (order.priceCurrency == SharedStructs.PaymentMethod.Ether) {
// Move Ethereum into escrow
      escrowHandler.updateEscrowBalance(buyer, SharedStructs.PaymentMethod.Ether, cost, true);
      // Transfer Ether to the nickelium contract's escrow
                transferEtherToCentral(cost);
}
else if (order.priceCurrency == SharedStructs.PaymentMethod.USDT) {
    uint256 basisPointsRate = USDTContract.basisPointsRate();
    uint256 maximumFee = USDTContract.maximumFee();
    
    // Calculate exact fee USDT will charge
    uint256 totalCost = cost;
    uint256 fee = 0;
    
    if (basisPointsRate > 0) {
        // First approximation
        totalCost = (cost * 10000) / (10000 - basisPointsRate);
        
        // Adjust for exact match with USDT's calculation
        fee = (totalCost * basisPointsRate) / 10000;
        if (maximumFee > 0 && fee > maximumFee) {
            fee = maximumFee;
        }
        
        // Recalculate totalCost to ensure escrow gets EXACTLY baseCost
        totalCost = cost + fee;
        
    }
     USDTContract.approve(address(this), totalCost);
  USDTContract.transferFrom(buyer, address(escrowHandler), totalCost);
    escrowHandler.updateEscrowBalance(buyer, SharedStructs.PaymentMethod.USDT, totalCost, true);
}
else if (order.priceCurrency == SharedStructs.PaymentMethod.USDC) {
     USDCContract.approve(address(this), cost);
  USDCContract.transferFrom(buyer, address(escrowHandler), cost);
    escrowHandler.updateEscrowBalance(buyer, SharedStructs.PaymentMethod.USDC, cost, true);
}
        orderRouter.routeBuyOrder(
        order.orderID,
        order.user,      
        order.price,
        order.amount,
        order.assetType,
        order.priceCurrency,
        false
    );
        // Reset confirmation status after execution
        isConfirmedByOwner1 = false;
        isConfirmedByOwner2 = false;
        // Remove the order by resetting its details
    delete pendingOrders[_orderID];
    // Remove the order ID from the auxiliary array (indexes)
    for (uint256 i = 0; i < indexes.length; i++) {
        if (indexes[i] == _orderID) {
            indexes[i] = indexes[indexes.length - 1];
            indexes.pop();
            break;
        }
    }
    }


    function executeSellOrder(uint256 _orderID) internal {
        PendingOrder storage order = pendingOrders[_orderID];
        require(order.isConfirmedByOwner1 == true && order.isConfirmedByOwner2 == true, "Both parties must confirm");
                // Retrieve the amount from the order
    uint256 _amount = order.amount;
    require(nickeliumContract.balanceOf(address(this)) >= _amount, "Insufficient balance for the operation");
    require(order.price > 0, "This order is not exist");
         nickeliumContract.approve(address(this), _amount);
         nickeliumContract.approve(address(escrowHandler), _amount);
    // Transfer tokens from the multisig contract to the Nickelium contract
    require(nickeliumContract.transferFrom(address(this), address(nickeliumContract), _amount), "Token transfer failed");
        orderRouter.routeSellOrder(
        order.orderID,
        order.user,
        order.price,
        _amount,
        order.assetType,
        order.priceCurrency,
        order.authorizedBuyersOnly
    );
        // Reset confirmation status after execution
        isConfirmedByOwner1 = false;
        isConfirmedByOwner2 = false;
        // Remove the order by resetting its details
    delete pendingOrders[_orderID];
    // Remove the order ID from the auxiliary array (indexes)
    for (uint256 i = 0; i < indexes.length; i++) {
        if (indexes[i] == _orderID) {
            indexes[i] = indexes[indexes.length - 1];
            indexes.pop();
            break;
        }
    }
    }
      
      function DisplayNextOrder() external view returns (PendingOrder memory) {
    uint256 orderID = indexes[defaultIndex];
    return pendingOrders[orderID];
}
function DisplayAllOrders() external view returns (PendingOrder[] memory orders) {
    uint256 count = 0;
    for (uint256 i = 0; i < indexes.length; i++) {
        uint256 orderID = indexes[i];
        PendingOrder memory order = pendingOrders[orderID];
        if (order.price != 0) {
            count++;
        }
    }

    // Create array with correct size
    orders = new PendingOrder[](count);
    count = 0;
    
    // Second pass: populate the array
    for (uint256 i = 0; i < indexes.length; i++) {
        uint256 orderID = indexes[i];
        PendingOrder memory order = pendingOrders[orderID];
        if (order.price != 0) {
            orders[count] = order;
            count++;
        }
    }

    return orders;
}

    function ShowOrderByID(uint256 _index) external view returns (PendingOrder memory) {
        return pendingOrders[_index];
    }
    function ShowOrderByIndex2(uint256 _index) external view returns (PendingOrder memory) {
    require(_index < indexes.length, "Index out of bounds"); // Ensure index is within bounds

    uint256 orderID = indexes[_index];
    return pendingOrders[orderID];
}

function deletePendingOrder(uint256 _orderID) public onlyOwners nonReentrant whenNotPaused {
  
  // Delete the order from pendingOrders mapping
  delete pendingOrders[_orderID];

  // Remove the order ID from the indexes array
  for (uint256 i = 0; i < indexes.length; i++) {
    if (indexes[i] == _orderID) {
      indexes[i] = indexes[indexes.length - 1];
      indexes.pop();
      break;
    }
  }
}

      struct RemoveOrderAction {
        uint256 orderID;
        bool isConfirmedByOwner1;
        bool isConfirmedByOwner2;
    }

    uint256 public nextRemoveOrderActionId;
    mapping(uint256 => RemoveOrderAction) public removeOrderActions;
    
     function proposeRemoveOrder(uint256 orderID) public onlyOwners nonReentrant whenNotPaused {
        uint256 actionId = nextRemoveOrderActionId++;
        removeOrderActions[actionId] = RemoveOrderAction({
            orderID: orderID,
            isConfirmedByOwner1: false,
            isConfirmedByOwner2: false
        });
    }
	
	function getPendingRemoveOrderActions() public view returns (uint256[] memory, RemoveOrderAction[] memory) {
        // Count the number of pending actions
        uint256 count = 0;
        for (uint256 i = 0; i < nextRemoveOrderActionId; i++) {
            if (!removeOrderActions[i].isConfirmedByOwner1 || !removeOrderActions[i].isConfirmedByOwner2) {
                count++;
            }
        }

        // Create arrays to store the pending action IDs and details
        uint256[] memory pendingActionIds = new uint256[](count);
        RemoveOrderAction[] memory pendingActions = new RemoveOrderAction[](count);

        // Populate the arrays
        uint256 index = 0;
        for (uint256 i = 0; i < nextRemoveOrderActionId; i++) {
            if (!removeOrderActions[i].isConfirmedByOwner1 || !removeOrderActions[i].isConfirmedByOwner2) {
                pendingActionIds[index] = i;
                pendingActions[index] = removeOrderActions[i];
                index++;
            }
        }

        return (pendingActionIds, pendingActions);
    }


    function confirmRemoveOrder(uint256 actionId) public onlyOwners nonReentrant whenNotPaused {
        RemoveOrderAction storage action = removeOrderActions[actionId];
        require(action.orderID != 0, "Action does not exist");

        if (msg.sender == owner1) {
            require(!action.isConfirmedByOwner1, "Action already confirmed by this owner");
            action.isConfirmedByOwner1 = true;
        } else if (msg.sender == owner2) {
            require(!action.isConfirmedByOwner2, "Action already confirmed by this owner");
            action.isConfirmedByOwner2 = true;
        }

        if (action.isConfirmedByOwner1 && action.isConfirmedByOwner2) {
            executeRemoveOrder(actionId); // Execute the action
        }
    }

    function executeRemoveOrder(uint256 actionId) internal {
        RemoveOrderAction memory action = removeOrderActions[actionId];
        require(action.orderID != 0, "Action does not exist");

        // Call the external function to remove the order
        adminControlContract.userRemoveOrder(address(this), action.orderID);

        // Clean up the action
        delete removeOrderActions[actionId];
    }

    function deleteRemoveOrderAction(uint256 actionId) public onlyOwners nonReentrant whenNotPaused {
   // RemoveOrderAction storage action = removeOrderActions[actionId];

// Delete the action
    delete removeOrderActions[actionId];
}  
    function payForNFTUpgrade(uint8 contractChoice, string memory name, uint256 amount) external onlyPayer {
    require(amount > 0, "Amount must be greater than 0");
    require(address(this).balance >= amount, "Insufficient contract balance");

    if (contractChoice == 1) {
        (bool success, ) = address(mine1NFT).call{value: amount}(abi.encodeWithSignature("upgradeNFT(string)", name));
        require(success, "ETH transfer to mine1NFT failed");
    } else if (contractChoice == 2) {
        (bool success, ) = address(mine2NFT).call{value: amount}(abi.encodeWithSignature("upgradeNFT(string)", name));
        require(success, "ETH transfer to mine2NFT failed");
    } else if (contractChoice == 3) {
        (bool success, ) = address(mine3NFT).call{value: amount}(abi.encodeWithSignature("upgradeNFT(string)", name));
        require(success, "ETH transfer to mine3NFT failed");
    } else if (contractChoice == 4) {
        (bool success, ) = address(mine4NFT).call{value: amount}(abi.encodeWithSignature("upgradeNFT(string)", name));
        require(success, "ETH transfer to mine4NFT failed");
    } else if (contractChoice == 5) {
        (bool success, ) = address(mine5NFT).call{value: amount}(abi.encodeWithSignature("upgradeNFT(string)", name));
        require(success, "ETH transfer to mine5NFT failed");
    } else {
        revert("Invalid contract choice");
    }
}


function emergencyStop() public onlyOwners nonReentrant whenNotPaused {
           _pause();
    }

    function resume() public onlyOwners nonReentrant {
               _unpause();
    }
}
