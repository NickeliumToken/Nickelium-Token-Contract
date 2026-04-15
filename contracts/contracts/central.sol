// SPDX-License-Identifier: Custom-License
/*This contract is part of Nickelium Token Ecosystem and is property of Destrier LLC. You are granted permission to use all functions of this contract intended for users. 
*However, copying, modifying, or distributing the code is strictly prohibited without explicit permission from the author.
*All rights reserved. Destrier LLC, registration number 20241316871 , Colorado , USA.*/

pragma solidity ^0.8.0;


import "@openzeppelin/contracts/utils/math/Math.sol";
import "https://github.com/abdk-consulting/abdk-libraries-solidity/blob/master/ABDKMath64x64.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/utils/Pausable.sol";
import "./IEscrowHandler.sol";
import "./SharedStructs.sol";
import "./IAdminControl.sol";
import "./IBalances.sol";
import "./IUSDCorders.sol";
import "./INickelium.sol";
import "./IUSDTorders.sol";

contract Central is ReentrancyGuard, Pausable {
    address public multisig;
    address public owner;
    address payable public feeRecipient; // Address that receives fees
    mapping(address => bool) public authorizedAddresses;
    mapping(address => bool) public authorizedBuyersMap; 
    address[] public authorizedBuyersList; 
    mapping(address => bool) public priceChanger;
     using ABDKMath64x64 for int128;
     uint256 public LMEprice;
     uint256 public LMEpriceInEther;   // Price in Ether (wei)
     uint256 public No; // Stable value
     // Fee percentage expressed in basis points (i.e. 10000 basis points = 100%)
    // For example, 200 basis points = 2%
    uint256 public feePercentage; // e.g., 200 for 2%
    // Fee cap in wei; even if the percentage fee is high, the fee will not exceed this amount.
    uint256 public feeCap;
    uint256 public usdtPerEth;
    uint256 public dailyPrice; // price of nickel per tone daily
    event FeeUpdated(uint256 feePercentage, uint256 feeCap);
    IBalances public balancesContract;
    IEscrowHandler public escrowHandler;
    IAdminControl public adminControl;
    IUSDCorders public usdcOrders;
    IUSDTorders public usdtOrders;
    INickelium public nickeliumContract;
    constructor (uint256 _initialNo) {
         authorizedAddresses[msg.sender] = true;
        No = _initialNo;
        priceChanger[msg.sender] = true;
    }
    function setOwner(address newOwner) public onlyAuthorized {
        owner = newOwner;
    }

    function updateDailyPrice(uint256 _newPrice) public onlyPriceChanger {
        // Update the daily price
        dailyPrice = _newPrice;

        // Check and update No price if necessary
        if (_newPrice < No) {
            No = _newPrice;
        }
    }

    function getDailyPrice() internal view returns (uint256) {
        // Replace this with actual logic to fetch the daily price
        return dailyPrice; // Example value
    }

    function update_LME_price() public onlyPriceChanger {
    
    uint256 exponentiationResultUInt;
    
    // If dailyPrice is less than or equal to No, we can't compute ln(dailyPrice-No)
    // So use a fallback value (here, 10000) for the exponentiation result.
    if (dailyPrice == No) {
        exponentiationResultUInt = 10000;
    } else {
        // Calculate (dailyPrice - No)^(1.618) using ABDKMath64x64 fixed-point math
        
        // Convert (dailyPrice - No) to fixed-point (64.64)
        int128 base = ABDKMath64x64.fromUInt(dailyPrice - No);
        // Represent 1.618 as a fixed-point number: 1618/1000
        int128 exponent = ABDKMath64x64.divu(1618, 1000);
        
        // Compute ln(base) and then exponentiation: exp( exponent * ln(base) )
        int128 lnBase = ABDKMath64x64.ln(base);
        int128 product = ABDKMath64x64.mul(lnBase, exponent);
        int128 exponentiationResult = ABDKMath64x64.exp(product);
        
        // Convert the result back to uint256
        exponentiationResultUInt = ABDKMath64x64.toUInt(exponentiationResult);
    }
    
    // Calculate max[10000, (dailyPrice - No)^1.618]
    uint256 maxValue = Math.max(10000, exponentiationResultUInt);
    
    // Calculate the new LME price: (dailyPrice + maxValue) / 10000
    uint256 newLMEprice = ((dailyPrice + maxValue) * 1e6) / 10000;
    
    // Update LMEprice and emit the event
    LMEprice = newLMEprice;
    LMEpriceInEther = (newLMEprice * 1e18) / usdtPerEth;
    emit PriceUpdated(newLMEprice);
}
      function updateAllPrices(uint256 _newPrice) external onlyPriceChanger {
    updateDailyPrice(_newPrice);
    update_LME_price();
}

    // This function allows an authorized caller (e.g., an oracle) to update the price.
    function setUSDTPerETH(uint256 _newPrice) external onlyPriceChanger {
        usdtPerEth = _newPrice;
        emit PriceUpdated(_newPrice);
    }

    function getUSDTPerETH() public view returns (uint256) {
        return usdtPerEth;
    }

     /*function setFee(uint256 _feePercentage, uint256 _feeCap) external onlyAuthorized {
        feePercentage = _feePercentage;
        feeCap = _feeCap;
        emit FeeUpdated(_feePercentage, _feeCap);
    }*/

    function setFee(uint256 _feePercentage, uint256 _feeCap) external onlyAuthorized {
    require(_feePercentage <= 300, "Fee cannot exceed 3% (300 basis points)");
    feePercentage = _feePercentage;
    feeCap = _feeCap;
    emit FeeUpdated(_feePercentage, _feeCap);
}

     function setFeeRecipient(address payable _newFeeRecipient) external onlyAuthorized {
        require(_newFeeRecipient != address(0), "Fee recipient cannot be zero address");
        feeRecipient = _newFeeRecipient;
    }

    modifier onlyPriceChanger() {
        require(priceChanger[msg.sender], "Not authorized");
        _;
    }

    function setPriceChanger(address _address, bool _status) public onlyAuthorized nonReentrant whenNotPaused {
        priceChanger[_address] = _status;
    }

    // Event to log price updates
    event PriceUpdated(uint256 newPrice);
    // In the Nickelium contract
function setAuthorizedBuyer(address buyer, bool _status) public onlyAuthorized nonReentrant {
    require(buyer != address(0), "Buyer address cannot be zero");

    if (_status) {
        // If setting to true, add to mapping and array if not already present
        if (!authorizedBuyersMap[buyer]) {
            authorizedBuyersMap[buyer] = true;
            authorizedBuyersList.push(buyer); // Add to the array

            // Call Balances contract to update the backup
            balancesContract.setAuthorizedBuyerBackup(buyer, true);
        }
    } else {
        // If setting to false, remove from mapping and array
        if (authorizedBuyersMap[buyer]) {
            authorizedBuyersMap[buyer] = false;
            // Remove from the array
            for (uint256 i = 0; i < authorizedBuyersList.length; i++) {
                if (authorizedBuyersList[i] == buyer) {
                    // Move the last element to the index being removed and pop the last element
                    authorizedBuyersList[i] = authorizedBuyersList[authorizedBuyersList.length - 1];
                    authorizedBuyersList.pop();
                    break;
                }
            }

            // Call Balances contract to update the backup
            balancesContract.setAuthorizedBuyerBackup(buyer, false);
        }
    }
}
      
      // In the new Nickelium contract
function migrateAuthorizedBuyersFromBackup() external onlyAuthorized {
    uint256 count = balancesContract.getAuthorizedBuyersCount();
    for (uint256 i = 0; i < count; i++) {
        address buyer = balancesContract.getAuthorizedBuyerAtIndex(i);
        if (balancesContract.isAuthorizedBuyer(buyer)) {
            authorizedBuyersMap[buyer] = true;
            authorizedBuyersList.push(buyer);
        }
    }
}

       function getAllAuthorizedBuyers() public view returns (address[] memory) {
    return authorizedBuyersList;
      }

      
   function isAuthorizedBuyer(address buyer) public view returns (bool) {
    return authorizedBuyersMap[buyer];
}

      // Function to check if a buyer is authorized and get their index
function CheckAuthorizedBuyer(address buyer) public view returns (uint256, bool) {
    return findBuyerIndex(buyer);
      }
      function findBuyerIndex(address buyer) internal view returns (uint256, bool) {
    for (uint256 i = 0; i < authorizedBuyersList.length; i++) {
        if (authorizedBuyersList[i] == buyer) {
            return (i, true); // Return the index and true if found
        }
    }
    return (0, false); // Return 0 and false if not found
    }

    modifier onlyAuthorized() {
        require(authorizedAddresses[msg.sender], "Not authorized");
        _;
    }

    function setAuthorizedAddress(address _address, bool _status) public onlyAuthorized nonReentrant whenNotPaused {
        authorizedAddresses[_address] = _status;
    }

    function setContracts(
        address _usdcOrdersAddress,
        address _usdtOrdersAddress,
        address _escrowHandler,
        address _adminControl,
        address _balancesContract,
        address _nickeliumAddress,
        address _multisig
    ) public onlyAuthorized nonReentrant whenNotPaused {

        // Setting USDC Orders Contract
        usdcOrders = IUSDCorders(_usdcOrdersAddress);
        usdtOrders = IUSDTorders(_usdtOrdersAddress);
        
        // setting Nickelium address
        nickeliumContract = INickelium(_nickeliumAddress);

        // Setting EscrowHandler
        escrowHandler = IEscrowHandler(_escrowHandler);

        // Setting AdminControl
        adminControl = IAdminControl(_adminControl);

        // Setting Balances Contract
        balancesContract = IBalances(_balancesContract);

        // Setting Multisig Contract
        multisig = _multisig;
    }

    // Fallback function to handle incoming Ether
    fallback() external payable {
        // Log an event or update state as needed
        emit EtherReceived(msg.sender, msg.value);
    }
     event EtherReceived(address indexed sender, uint256 amount);

         
    mapping (address => mapping (address => uint256)) private _allowances;
uint256 public nextOrderID = 1;

  // Mapping to store user Nickelium coin balances
  mapping(address => uint256) public balances;

  modifier onlyMultisig() {
        require(msg.sender == multisig, "Only the multisig contract can call this function");
        _;
    }
// Function to get the next available order ID
    function getNextOrderID() external onlyAuthorized returns (uint256) {
        uint256 currentOrderID = nextOrderID;
        nextOrderID++; // Increment for the next order
        return currentOrderID;
    }
  
    // Function to allow Contract B to transfer Ether
    function releaseEther(address payable seller, uint amount) external onlyAuthorized whenNotPaused {
        
        seller.transfer(amount);
      //  contractBalance -= amount;
    }

    function revertEther(address sender, uint amount) external onlyAuthorized whenNotPaused {
    require(sender != address(0), "Invalid sender address");
    payable(sender).transfer(amount);
    } 

    function getContractBalanceEther() public view returns (uint256) {
    return address(this).balance;
}

    
 function placeBuyOrderEther(address buyer, uint256 _price, uint256 _amount) external payable onlyAuthorized nonReentrant whenNotPaused {
     //require(_price >= LMEpriceInEther, "Order price must be at least the current LME price");

        // Calculate the order cost.
        uint256 cost = (_price * _amount) / 1000;

        // Calculate the raw fee (percentage fee).
        uint256 rawFee = (cost * feePercentage) / 10000;

        // Apply the fee cap: use the lower of rawFee and feeCap.
        uint256 orderFee = Math.min(rawFee, feeCap);

        // Total amount required: cost + fee.
        uint256 totalRequired = cost + orderFee;
        require(msg.value >= totalRequired, "Insufficient Ether for order cost and fee");

        // Transfer fee to the feeRecipient.
        feeRecipient.transfer(orderFee);

        // Refund any excess Ether.
        uint256 excess = msg.value - totalRequired;
// Convert msg.sender to payable address
address payable senderPayable = payable(buyer);
  
// Return excess Ether
if (excess > 0) {
    senderPayable.transfer(excess);
}
uint256 orderID = nextOrderID++;
// Move Ethereum into escrow
      escrowHandler.updateEscrowBalance(buyer, SharedStructs.PaymentMethod.Ether, cost, true);

        // Call the EscrowHandler contract to place the order
        escrowHandler.addBuyOrder(uint(orderID), payable (buyer), _price, _amount, SharedStructs.AssetType.Nickelium, SharedStructs.PaymentMethod.Ether, false);
    }
    
    function placeBuyOrderUSDT(address buyer, uint256 _price, uint256 _amount) external payable onlyAuthorized nonReentrant whenNotPaused {
    
     uint256 cost = (_price * _amount) / 1000;
     uint256 feeInUSDT = (cost * feePercentage) / 10000;
      uint256 feeUSDTInEther = (feeInUSDT * 1 ether) / usdtPerEth;
     uint256 feeInEther = Math.min(feeUSDTInEther, feeCap);

    // Verify that the attached Ether covers the fee.
    require(msg.value >= feeInEther, "Insufficient Ether for fee");

    // Transfer the fee to the feeRecipient.
    feeRecipient.transfer(feeInEther);

    // Refund any excess Ether back to the buyer.
    uint256 excess = msg.value - feeInEther;
    if (excess > 0) {
        payable(buyer).transfer(excess);
    }

     uint256 orderID = nextOrderID++;

        escrowHandler.updateEscrowBalance(buyer, SharedStructs.PaymentMethod.USDT, cost, true);
        usdtOrders.addBuyOrder(uint(orderID), payable (buyer), _price, _amount, SharedStructs.AssetType.Nickelium, SharedStructs.PaymentMethod.USDT, false);
    }

    function placeBuyOrderUSDC(address buyer, uint256 _price, uint256 _amount) external payable onlyAuthorized nonReentrant whenNotPaused {
   uint256 cost = (_price * _amount) / 1000;
    
     uint256 feeInUSDC = (cost * feePercentage) / 10000;
      uint256 feeUSDCInEther = (feeInUSDC * 1 ether) / usdtPerEth;
     uint256 feeInEther = Math.min(feeUSDCInEther, feeCap);

    // Verify that the attached Ether covers the fee.
    require(msg.value >= feeInEther, "Insufficient Ether for fee");

    // Transfer the fee to the feeRecipient.
    feeRecipient.transfer(feeInEther);

    // Refund any excess Ether back to the buyer.
    uint256 excess = msg.value - feeInEther;
    if (excess > 0) {
        payable(buyer).transfer(excess);
    }
    uint256 orderID = nextOrderID++;

    escrowHandler.updateEscrowBalance(buyer, SharedStructs.PaymentMethod.USDC, cost, true);
    usdcOrders.addBuyOrder(uint(orderID), payable(buyer), _price, _amount, SharedStructs.AssetType.Nickelium, SharedStructs.PaymentMethod.USDC, false);
    }
    
    
   function placeSellOrderEther(address seller, uint256 _price, uint256 _amount) external payable onlyAuthorized nonReentrant whenNotPaused {
     //  require(_price >= LMEpriceInEther, "Order price must be at least the current LME price");
       // Calculate the order cost.
        uint256 cost = (_price * _amount) / 1000;

        // Calculate the raw fee (percentage fee).
        uint256 rawFee = (cost * feePercentage) / 10000;

        // Apply the fee cap: use the lower of rawFee and feeCap.
        uint256 orderFee = Math.min(rawFee, feeCap);

        // Total amount required: cost + fee.
        uint256 totalRequired = orderFee;
        require(msg.value >= totalRequired, "Insufficient Ether for order cost and fee");

        // Transfer fee to the feeRecipient.
        feeRecipient.transfer(orderFee);

        // Refund any excess Ether.
        uint256 excess = msg.value - totalRequired;
// Convert msg.sender to payable address
address payable senderPayable = payable(seller);
  
// Return excess Ether
if (excess > 0) {
    senderPayable.transfer(excess);
}
      uint256 orderID = nextOrderID++;
    escrowHandler.addSellOrder(uint(orderID), payable(seller), _price, _amount, SharedStructs.AssetType.Nickelium, SharedStructs.PaymentMethod.Ether, false);
    }
        
    function placeSellOrderUSDT(address seller, uint256 _price, uint256 _amount) external payable onlyAuthorized nonReentrant whenNotPaused {
    //  require(_price >= LMEprice, "Order price must be at least the current LME price");
      uint256 cost = (_price * _amount) / 1000;
     uint256 feeInUSDT = (cost * feePercentage) / 10000;
      uint256 feeInEther = (feeInUSDT * 1 ether) / usdtPerEth;
     uint256 totalFeeInEther = Math.min(feeInEther, feeCap);
    // Convert the USDT fee into an equivalent amount of Ether.
    // Assume getUSDTPerETH() returns the number of USDT (in smallest units) per 1 ETH.
    // uint256 usdtPerEth = getUSDTPerETH();  e.g., 3000 * 10**6 if 1 ETH = 3000 USDT and USDT has 6 decimals.
   

    // Verify that the attached Ether covers the fee.
    require(msg.value >= totalFeeInEther, "Insufficient Ether for fee");

    // Transfer the fee to the feeRecipient.
    feeRecipient.transfer(totalFeeInEther);

    // Refund any excess Ether back to the buyer.
    uint256 excess = msg.value - totalFeeInEther;
    if (excess > 0) {
        payable(seller).transfer(excess);
    }
    uint256 orderID = nextOrderID++;
    
        usdtOrders.addSellOrder(uint(orderID), payable(seller), _price, _amount, SharedStructs.AssetType.Nickelium, SharedStructs.PaymentMethod.USDT, false);
    }

    function placeSellOrderUSDC(address seller, uint256 _price, uint256 _amount) external payable onlyAuthorized nonReentrant whenNotPaused {
  //  require(_price >= LMEprice, "Order price must be at least the current LME price");
    uint256 cost = (_price * _amount) / 1000;
     uint256 feeInUSDC = (cost * feePercentage) / 10000;
      uint256 feeInEther = (feeInUSDC * 1 ether) / usdtPerEth;
     uint256 totalFeeInEther = Math.min(feeInEther, feeCap);
    // Verify that the attached Ether covers the fee.
    require(msg.value >= totalFeeInEther, "Insufficient Ether for fee");

    // Transfer the fee to the feeRecipient.
    feeRecipient.transfer(totalFeeInEther);

    // Refund any excess Ether back to the buyer.
    uint256 excess = msg.value - totalFeeInEther;
    if (excess > 0) {
        payable(seller).transfer(excess);
    }
    uint256 orderID = nextOrderID++;
    
    usdcOrders.addSellOrder(uint(orderID), payable(seller), _price, _amount, SharedStructs.AssetType.Nickelium, SharedStructs.PaymentMethod.USDC, false);
    }

// Function to get the Ether balance of an account
function getEtherBalance(address account) public view returns (uint256) {
    return account.balance;
}

/*function removeOrder(SharedStructs.Order[] storage orders, uint index) internal {
    require(index < orders.length, "Index out of bounds");

    for (uint i = index; i < orders.length - 1; i++) {
        orders[i] = orders[i + 1];
    }
    orders.pop();
    
}*/


function pause() external onlyAuthorized nonReentrant whenNotPaused {
        _pause();
    }

    function unpause() external onlyAuthorized nonReentrant {
        _unpause();
    }



}