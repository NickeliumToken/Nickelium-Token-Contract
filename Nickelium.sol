/* SPDX-License-Identifier: Custom-License
*This contract is property of Destrier LLC. You are granted permission to use all functions of this contract intended for users. 
*However, copying, modifying, or distributing the code is strictly prohibited without explicit permission from the author.
*All rights reserved. Destrier LLC, registration number 20241316871 , Colorado , USA.*/


pragma solidity ^0.8.0;

interface INFTContract {
    function stockLimit() external view returns (uint256);
    // Existing function
    function upgradeNFT(string memory name) external payable;
    // New functions
    function increaseUsedStock(uint256 amount, NickelType nickelType) external;
    function setStockLimit(uint256 newLimit) external;
}
import "./NickelType.sol";
import "abdk-libraries-solidity/ABDKMath64x64.sol";
import "@openzeppelin/contracts/utils/math/Math.sol"; 
import "./IEscrowHandler.sol";
import "./SharedStructs.sol";
import "./ICentral.sol";
import "./IAdminControl.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "./IUSDCorders.sol";
import "./IBalances.sol";
import "./IUSDTorders.sol";
import "./ITether.sol";


contract Nickelium is ERC20 ,ReentrancyGuard, Pausable{
     mapping(address => bool) public authorizedAddresses;
    ICentral public central;
    IEscrowHandler public escrowHandler;
    //ICentral public iCentral;
    IAdminControl public adminControlContract;
    ITether public USDTContract;
    //address public usdtContractAddress;
    address public admin;
    IERC20 public USDCContract;
    //address public usdcContractAddress;
    IUSDCorders public usdcOrders;
    IUSDTorders public usdtOrders;
    IBalances public balancesContract;
     mapping (address => mapping (address => uint256)) private _allowances;
  // Declare the owner state variable
    address public owner;
    uint256 public TokenUnitsStock; // Total units in stock
    uint256 public totalNickelInStock; // Total Nickelium in stock in grams

     INFTContract public mine1NFT;
    INFTContract public mine2NFT;
    INFTContract public mine3NFT;
    INFTContract public mine4NFT;
    INFTContract public mine5NFT;
    
    constructor() ERC20("Nickelium", "NCL") {
   admin = msg.sender;
        authorizedAddresses[msg.sender] = true;
          // Total amount of Nickelium in stock in grams
 //totalNickelInStock = 11715938000; // 11715.9384 tons = 11715938000 grams
    totalNickelInStock = 0;

        // Initialize total wei in stock
   // TokenUnitsStock = totalNickelInStock * 1000 / 100 ; // Total wei that the stock can produce
     TokenUnitsStock = 0;
}
    /*constructor() ERC20("Nickelium", "NCL") {
        
        admin = msg.sender;
        authorizedAddresses[msg.sender] = true;
        priceChanger[msg.sender] = true;
          // Total amount of Nickelium in stock in grams
 totalNickeliumInStock = 11715938000; // 11715.9384 tons = 11715938000 grams

        // Initialize total wei in stock
    TokenUnitsStock = totalNickeliumInStock * 1000 / 100 ; // Total wei that the stock can produce
    }*/

    // decimals of Nickelium
    function decimals() public view virtual override(ERC20 ) returns (uint8) {
        return 3;
    }

    function setOwner(address newOwner) public onlyAuthorized {
        owner = newOwner;
    }
     // Function to allow only authorized users to update the suggested price
    /*function update_LME_price(uint256 _newPrice) public onlyPriceChanger {
        LMEprice = _newPrice;
    }*/
     // Custom max function for fixed-point numbers (64.64)
    /*function maxFixed(int128 a, int128 b) internal pure returns (int128) {
    if (b < 0) {
        return a;
    }
    return a >= b ? a : b;
    }*/
    
     /*function update_LME_price() public onlyPriceChanger {
        uint256 dailyPrice = getDailyPrice();
        int256 delta = int256(dailyPrice) - int256(No); // Handles negative values
        int128 base = ABDKMath64x64.fromInt(delta);
        int128 exponent = ABDKMath64x64.divu(1618, 1000);
        int128 exponentiationResult = ABDKMath64x64.pow(base, exponent);
        uint256 exponentiationResultUInt = ABDKMath64x64.toUInt(exponentiationResult);

        uint256 maxValue = Math.max(10000, exponentiationResultUInt);
        uint256 newLMEprice = (dailyPrice + maxValue) / 10000;

        LMEprice = newLMEprice;
        emit PriceUpdated(newLMEprice);
    }*/
    // Function to read the suggested price - this will be visible on the Read tab in Etherscan
    
    modifier onlyAuthorized() {
        require(authorizedAddresses[msg.sender], "Not authorized");
        _;
    }

    function setAuthorizedAddress(address _address, bool _status) public onlyAuthorized nonReentrant whenNotPaused {
        authorizedAddresses[_address] = _status;
    }

    function setNFTContracts(
    address _mine1NFTAddress,
    address _mine2NFTAddress,
    address _mine3NFTAddress,
    address _mine4NFTAddress,
    address _mine5NFTAddress
) public onlyAuthorized nonReentrant whenNotPaused {
    mine1NFT = INFTContract(_mine1NFTAddress);
    mine2NFT = INFTContract(_mine2NFTAddress);
    mine3NFT = INFTContract(_mine3NFTAddress);
    mine4NFT = INFTContract(_mine4NFTAddress);
    mine5NFT = INFTContract(_mine5NFTAddress);
}

    function setContracts (
             address _centralAddress,
        address _escrowHandlerAddress,
        address _adminControlAddress,
        address _usdtAddress,
        address _usdcAddress,
        address _usdcOrdersAddress,
        address _usdtOrdersAddress,
        address _balancesContract
    ) public onlyAuthorized nonReentrant whenNotPaused {
        // Set Nickelium and its interface
        address payable payableCentralAddress = payable(_centralAddress);
        central = ICentral(payableCentralAddress);
        //iCentral = ICentral(_centralAddress);

        // Set EscrowHandler
        escrowHandler = IEscrowHandler(_escrowHandlerAddress);

        // Set AdminControl
        adminControlContract = IAdminControl(_adminControlAddress);

        // Set USDTContract and address
        USDTContract = ITether(_usdtAddress);
        //usdtContractAddress = _usdtAddress;

        // Set USDCContract and address
    USDCContract = IERC20(_usdcAddress);  
    //usdcContractAddress = _usdcAddress;   

    // Setting USDC Orders Contract
        usdcOrders = IUSDCorders(_usdcOrdersAddress);
        usdtOrders = IUSDTorders(_usdtOrdersAddress);
        // Setting Balances Contract
        balancesContract = IBalances(_balancesContract);
        
    }
    // Fallback function to handle incoming Ether
      // Event to log price updates
    event PriceUpdated(uint256 newPrice);

    function GetStockOfAllMines() public view returns (uint256 totalStockLimit) {
    totalStockLimit = mine1NFT.stockLimit() +
                      mine2NFT.stockLimit() +
                      mine3NFT.stockLimit() +
                      mine4NFT.stockLimit() +
                      mine5NFT.stockLimit();
}

     // add Nickelium  to stock in grams
  /*function addNickelToStock(uint256 amountGrams) public onlyAuthorized nonReentrant whenNotPaused {
    require(amountGrams % 5 == 0, "Amount must be divisible by 5");

    uint256 amountPerContract = amountGrams / 5;

    mine1NFT.increaseUsedStock(amountPerContract);
    mine2NFT.increaseUsedStock(amountPerContract);
    mine3NFT.increaseUsedStock(amountPerContract);
    mine4NFT.increaseUsedStock(amountPerContract);
    mine5NFT.increaseUsedStock(amountPerContract);
   
    totalNickelInStock += amountGrams;

    // Update TokenUnitsStock based on the added Nickelium
    uint256 TokenUnits = amountGrams * 1e3 / 100 ;
    TokenUnitsStock += TokenUnits;
}*/
     function addNickelToStock(uint256 amountGrams, NickelType nickelType) public onlyAuthorized nonReentrant whenNotPaused {
    require(amountGrams % 5 == 0, "Amount must be divisible by 5");

    uint256 amountPerContract = amountGrams / 5;

    // Pass the nickel type to each mine contract
    mine1NFT.increaseUsedStock(amountPerContract, nickelType);
    mine2NFT.increaseUsedStock(amountPerContract, nickelType);
    mine3NFT.increaseUsedStock(amountPerContract, nickelType);
    mine4NFT.increaseUsedStock(amountPerContract, nickelType);
    mine5NFT.increaseUsedStock(amountPerContract, nickelType);
   
    totalNickelInStock += amountGrams;

    // Update TokenUnitsStock based on the added Nickel
    uint256 TokenUnits = amountGrams * 1e3 / 100;
    TokenUnitsStock += TokenUnits;
}
     
     function migrateBalances() public onlyAuthorized nonReentrant whenNotPaused {
        (address[] memory users, uint256[] memory userBalances) = balancesContract.getAllBalances();
        for (uint256 i = 0; i < users.length; i++) {
            mint(users[i], userBalances[i]);
        }
    }

    function mint(address account, uint256 TokenUnits) public onlyAuthorized nonReentrant whenNotPaused  {
    
    require(TokenUnitsStock >= TokenUnits, "Not enough units in stock to mint coins");

       // Decrease the total units in stock
    TokenUnitsStock -= TokenUnits;

    // Decrease the total Nickelium in stock based on the amount of coins being minted
    uint256 amountGrams = TokenUnits * 100 / 1e3; // Convert wei to grams (1 coin = 100 grams)
    totalNickelInStock -= amountGrams;

   // Convert units to tokens
    uint256 TokenAmount = TokenUnits ;

    // Mint the tokens (you can replace this with your actual minting logic)
    _mint(account, TokenAmount);
// Update the balances in the Balances contract
    balancesContract.updateBalance(account, balanceOf(account));
}

   function burn(uint256 amount) public nonReentrant whenNotPaused {
    address user = msg.sender; // Ensure that only the caller can burn their own tokens
    require(balanceOf(user) >= amount, "Insufficient balance to burn");

    // Burn the tokens
    _burn(user, amount);

    // Update the balances in the Balances contract
    balancesContract.updateBalance(user, balanceOf(user));

    // Increase the total Nickelium in stock based on the amount of coins being burned
    uint256 amountGrams = (amount * 100) / 1000; // Convert tokens to grams (1 coin = 100 grams)
    totalNickelInStock += amountGrams;

    // Increase the total wei in stock
    TokenUnitsStock += amount;
}



    function getNickelinStockGrams() public view returns (uint256) {
        return totalNickelInStock;
    }

    function checkNickeliumBalance(address account) public view returns (uint256) {
    return balanceOf(account);
}
    
function approveToken (address user, address spender, uint256 amount) public onlyAuthorized whenNotPaused returns (bool) {
    _approve(user, spender, amount);
    return true;
}

event TransferEvent(
    address indexed from,
    address indexed to,
    uint256 amount,
    uint256 price,          // LME price at time of transfer
    uint256 timestamp       // Optional: timestamp of the transfer
);


function transfer(address _to, uint256 amount) public whenNotPaused override(ERC20) returns (bool) {
    bool success = super.transfer(_to, amount);
    if (success) {
        balancesContract.updateBalance(msg.sender, balanceOf(msg.sender));
        balancesContract.updateBalance(_to, balanceOf(_to));
        
        // Get the LME price from the central contract
        uint256 currentPrice = central.LMEprice();
        
        // Emit the custom event with price data
        emit TransferEvent(
            msg.sender,
            _to,
            amount,
            currentPrice,
            block.timestamp
        );
    }
    return success;
}

// This function wraps the internal _transfer tokens function
    function transferFromContract(address recipient, uint256 amount) external onlyAuthorized whenNotPaused {
    // Ensure only the EscrowHandler can call this function
    _transfer(address(this), recipient, amount);
    // Update balances in the Balances contract
    balancesContract.updateBalance(address(this), balanceOf(address(this)));
    balancesContract.updateBalance(recipient, balanceOf(recipient));
}

    function getBuyOrdersEther() public view returns (SharedStructs.Order[] memory) {
        return escrowHandler.getBuyOrdersEther();
    }

    // Fetch sell orders in Ether for all users
    function getSellOrdersEther() public view returns (SharedStructs.Order[] memory) {
        return escrowHandler.getSellOrdersEther();
    }

    // Fetch buy orders in USDT for all users
    function getBuyOrdersUSDT() public view returns (SharedStructs.Order[] memory) {
        return usdtOrders.getBuyOrdersUSDT();
    }

    // Fetch sell orders in USDT for all users
    function getSellOrdersUSDT() public view returns (SharedStructs.Order[] memory) {
        return usdtOrders.getSellOrdersUSDT();
    }

    function getBuyOrdersUSDC() external view returns (SharedStructs.Order[] memory) {
    return usdcOrders.getBuyOrdersUSDC();
}
  
  function getSellOrdersUSDC() external view returns (SharedStructs.Order[] memory) {
    return usdcOrders.getSellOrdersUSDC();
}

   
   function placeBuyOrderEther(uint256 _price, uint256 _amount) public payable nonReentrant whenNotPaused {
    central.placeBuyOrderEther{value: msg.value}(msg.sender, _price, _amount);
    }

    
    /*function placeBuyOrderUSDT(uint256 _price, uint256 _amount) public payable nonReentrant whenNotPaused {
    uint256 totalCost = (_price * _amount) / 1000;
    uint256 balance = USDTContract.balanceOf(msg.sender);
   require(balance >= totalCost, "Insufficient USDT balance");
    // Transfer the total cost from the user's balance to the escrowHandler
    USDTContract.transferFrom(msg.sender, address(escrowHandler), totalCost);
    // Forward the order details (and attached Ether for fee) to the central contract.
    central.placeBuyOrderUSDT{value: msg.value}(msg.sender, _price, _amount);
    }*/
   /* function placeBuyOrderUSDT(uint256 _price, uint256 _amount) public payable nonReentrant whenNotPaused {
    uint256 totalCost = (_price * _amount) / 1000;
    
    // 1. Check USDT balance
    require(USDTContract.balanceOf(msg.sender) >= totalCost, "Insufficient USDT balance");
    
    // 2. Check USDT allowance
    require(USDTContract.allowance(msg.sender, address(this)) >= totalCost, "Insufficient allowance");
    
    // 3. Check contract pause status (if USDT is pausable)
    (bool isPaused,) = address(USDTContract).staticcall(abi.encodeWithSignature("paused()"));
    require(!isPaused, "USDT contract paused");
    
    // 4. Try transfer with error handling
    try USDTContract.transferFrom(msg.sender, address(escrowHandler), totalCost) {
        // 5. Forward to central contract if USDT transfer succeeds
        central.placeBuyOrderUSDT{value: msg.value}(msg.sender, _price, _amount);
    } catch Error(string memory reason) {
        revert(string(abi.encodePacked("USDT transfer failed: ", reason)));
    } catch (bytes memory) {
        revert("USDT transfer failed (unknown error)");
    }
}*/
    /*function placeBuyOrderUSDT(uint256 _price, uint256 _amount) public payable nonReentrant whenNotPaused {
        uint256 totalCost = (_price * _amount) / 1000;
        
        // 1. Check USDT balance
        require(USDTContract.balanceOf(msg.sender) >= totalCost, "Insufficient USDT balance");
        
        // 2. Check USDT allowance
        require(USDTContract.allowance(msg.sender, address(this)) >= totalCost, "Insufficient allowance");
        
        // 3. Check contract pause status using low-level call
        (bool pauseCheckSuccess, bytes memory pauseData) = address(USDTContract).staticcall(
            abi.encodeWithSelector(0x5c975abb) // bytes4(keccak256("paused()"))
        );
        require(pauseCheckSuccess, "USDT pause check failed");
        require(!abi.decode(pauseData, (bool)), "USDT contract paused");
        
        // 4. Execute transfer with full error handling
        (bool transferSuccess, bytes memory transferData) = address(USDTContract).call(
            abi.encodeWithSelector(
                0x23b872dd, // transferFrom(address,address,uint256)
                msg.sender,
                escrowHandler,
                totalCost
            )
        );
        
        if (!transferSuccess) {
            // Custom error handling for USDT-specific reverts
            if (transferData.length > 0) {
                // Bubble up USDT's revert reason
                assembly {
                    let data_len := mload(transferData)
                    revert(add(32, transferData), data_len)
                }
            } else {
                revert("USDT transfer failed (no reason given)");
            }
        }
        central.placeBuyOrderUSDT{value: msg.value}(msg.sender, _price, _amount);
    }*/

    /*function placeBuyOrderUSDT(uint256 _price, uint256 _amount) public payable nonReentrant whenNotPaused {
        uint256 baseCost = (_price * _amount) / 1000;
        
        // 1. Get USDT fee parameters (using low-level call)
        (bool feeRateSuccess, bytes memory feeRateData) = address(USDTContract).staticcall(
            abi.encodeWithSignature("basisPointsRate()")
        );
        require(feeRateSuccess, "Failed to get USDT fee rate");
        uint256 basisPointsRate = abi.decode(feeRateData, (uint256));
        
        // 2. Calculate total required USDT (amount + fee)
        uint256 fee = basisPointsRate > 0 ? (baseCost * basisPointsRate) / 10000 : 0;
        uint256 totalCost = baseCost + fee;
        
        // 3. Check balances and allowances
        require(USDTContract.balanceOf(msg.sender) >= totalCost, "Insufficient USDT balance");
        require(USDTContract.allowance(msg.sender, address(this)) >= totalCost, "Insufficient USDT allowance");
        
        // 4. Check USDT contract pause status
        (bool pauseSuccess, bytes memory pauseData) = address(USDTContract).staticcall(
            abi.encodeWithSignature("paused()")
        );
        require(pauseSuccess, "Failed to check USDT pause status");
        require(!abi.decode(pauseData, (bool)), "USDT contract paused");
        
        // 4. Execute transfer with full error handling
       (bool success, bytes memory data) = address(USDTContract).call(
            abi.encodeWithSelector(
                ITether.transferFrom.selector, // Compile-time checked
                msg.sender,
                escrowHandler,
                totalCost
            )
        );
        require(success, string(data));
        
        if (!success) {
            // Custom error handling for USDT-specific reverts
            if (data.length > 0) {
                // Bubble up USDT's revert reason
                assembly {
                    let data_len := mload(data)
                    revert(add(32, data), data_len)
                }
            } else {
                revert("USDT transfer failed (no reason given)");
            }
        }
        central.placeBuyOrderUSDT{value: msg.value}(msg.sender, _price, _amount);
    }*/

   /* function placeBuyOrderUSDT(uint256 _price, uint256 _amount) public payable nonReentrant whenNotPaused {
    // Combine operations to reduce variables
    uint256 totalCost;
    {
        uint256 baseCost = (_price * _amount) / 1000;
        
        // Get fee parameters
        (bool feeRateSuccess, bytes memory feeRateData) = address(USDTContract).staticcall(
            abi.encodeWithSignature("basisPointsRate()")
        );
        require(feeRateSuccess, "Failed to get USDT fee rate");
        uint256 basisPointsRate = abi.decode(feeRateData, (uint256));
        
        (bool maxFeeSuccess, bytes memory maxFeeData) = address(USDTContract).staticcall(
            abi.encodeWithSignature("maximumFee()")
        );
        require(maxFeeSuccess, "Failed to get USDT maximum fee");
        uint256 maximumFee = abi.decode(maxFeeData, (uint256));
        
        // Calculate fee
        uint256 fee = (baseCost * basisPointsRate) / 10000;
        if (fee > maximumFee && maximumFee > 0) {
            fee = maximumFee;
        }
        
        totalCost = baseCost + fee;
    }  // This scope helps clean up temporary variables
    
    // Check balances and allowances
    require(USDTContract.balanceOf(msg.sender) >= totalCost, "Insufficient USDT balance");
    require(USDTContract.allowance(msg.sender, address(this)) >= totalCost, "Insufficient USDT allowance");
    
    // Execute transfer
    (bool success, bytes memory data) = address(USDTContract).call(
        abi.encodeWithSelector(
            ITether.transferFrom.selector,
            msg.sender,
            escrowHandler,
            totalCost
        )
    );
    
    // Simplified error handling (the assembly block was using extra stack slots)
    require(success, data.length > 0 ? string(data) : "USDT transfer failed");
    
    // Pass parameters directly without storing
    central.placeBuyOrderUSDT{value: msg.value}(msg.sender, _price, _amount);
}*/

    function placeBuyOrderUSDT(uint256 _price, uint256 _amount) public payable nonReentrant whenNotPaused {
    uint256 baseCost = (_price * _amount) / 1000;
    
    // Get USDT fee parameters
    uint256 basisPointsRate = USDTContract.basisPointsRate();
    uint256 maximumFee = USDTContract.maximumFee();
    
    // Calculate exact fee USDT will charge
    uint256 totalCost = baseCost;
    uint256 fee = 0;
    
    if (basisPointsRate > 0) {
        // First approximation
        totalCost = (baseCost * 10000) / (10000 - basisPointsRate);
        
        // Adjust for exact match with USDT's calculation
        fee = (totalCost * basisPointsRate) / 10000;
        if (maximumFee > 0 && fee > maximumFee) {
            fee = maximumFee;
        }
        
        // Recalculate totalCost to ensure escrow gets EXACTLY baseCost
        totalCost = baseCost + fee;
        
    }
    
    // Check balances and allowances
    require(USDTContract.balanceOf(msg.sender) >= totalCost, "Insufficient balance");
    require(USDTContract.allowance(msg.sender, address(this)) >= totalCost, "Insufficient allowance");
    
    // Execute transfer
    (bool success, bytes memory data) = address(USDTContract).call(
        abi.encodeWithSelector(
            ITether.transferFrom.selector,
            msg.sender,
            escrowHandler,
            totalCost
        )
    );
    require(success, string(data));
    
    central.placeBuyOrderUSDT{value: msg.value}(msg.sender, _price, _amount);
}

    function placeBuyOrderUSDC(uint256 _price, uint256 _amount) public payable nonReentrant whenNotPaused {
    uint256 totalCost = (_price * _amount) / 1000;
    uint256 balance = USDCContract.balanceOf(msg.sender);
    require(balance >= totalCost, "Insufficient USDC balance");

    // Transfer the total cost from the user's balance to the escrowHandler
    USDCContract.transferFrom(msg.sender, address(escrowHandler), totalCost);

    central.placeBuyOrderUSDC{value: msg.value}(msg.sender, _price, _amount);
}

       
    function placeSellOrderEther( uint256 _price, uint256 _amount) public payable nonReentrant whenNotPaused {
        require(balanceOf(msg.sender) >= _amount, "Insufficient balance for the operation");
    require(_price * _amount / _price == _amount, "Potential overflow");
    bool success = transferFrom(msg.sender, address(this), _amount);
    require(success, "Token transfer failed");
        central.placeSellOrderEther{value: msg.value}(msg.sender , _price, _amount);
    }

    
    function placeSellOrderUSDT(uint256 _price, uint256 _amount) public payable nonReentrant whenNotPaused {
        require(balanceOf(msg.sender) >= _amount, "Insufficient balance for the operation");
    require(_price * _amount / _price == _amount, "Potential overflow");
    bool success = transferFrom(msg.sender, address(this), _amount);
    require(success, "Token transfer failed");
        central.placeSellOrderUSDT{value: msg.value}(msg.sender, _price, _amount);
    }

    function placeSellOrderUSDC(uint256 _price, uint256 _amount) public payable nonReentrant whenNotPaused {
        require(balanceOf(msg.sender) >= _amount, "Insufficient balance for the operation");
    require(_price * _amount / _price == _amount, "Potential overflow");
    bool success = transferFrom(msg.sender, address(this), _amount);
    require(success, "Token transfer failed");
    central.placeSellOrderUSDC{value: msg.value}(msg.sender, _price, _amount);
}

    function RemoveOrder(uint256 orderID) public nonReentrant whenNotPaused {
        adminControlContract.userRemoveOrder(msg.sender, orderID);
    }

    function changeBuyOrderPriceEther(uint256 orderID, uint256 newPrice) public payable nonReentrant whenNotPaused {
    //require(newPrice >= central.LMEprice(), "Order price must be at least the current LME price");
    escrowHandler.changeBuyOrderPriceEther{value: msg.value}(msg.sender, orderID, newPrice);
    }

   /* function changeBuyOrderPriceUSDT(uint256 orderID, uint256 newPrice) public nonReentrant whenNotPaused {
    //require(newPrice >= central.LMEprice(), "Order price must be at least the current LME price");
    // Retrieve all buy orders in USDT
    SharedStructs.Order[] memory buyOrders = usdtOrders.getBuyOrdersUSDT();
    
    // Iterate through the buy orders to find the one with the matching ID
    for (uint256 i = 0; i < buyOrders.length; i++) {
        if (buyOrders[i].orderID == orderID) {
            // Ensure only the owner of the order can change the price
            require(buyOrders[i].user == msg.sender, "Only the owner can change the price");

            uint256 remainingAmount = buyOrders[i].amount;
            uint256 oldCost = (buyOrders[i].price * remainingAmount) / 1000;
            uint256 newCost = (newPrice * remainingAmount) / 1000;

            // Handle additional cost if the new price is higher
            if (newCost > oldCost) {
	  uint256 additionalCost;
	  {
                uint256 baseCost = newCost - oldCost;
        
        // Get fee parameters
        (bool feeRateSuccess, bytes memory feeRateData) = address(USDTContract).staticcall(
            abi.encodeWithSignature("basisPointsRate()")
        );
        require(feeRateSuccess, "Failed to get USDT fee rate");
        uint256 basisPointsRate = abi.decode(feeRateData, (uint256));
        
        (bool maxFeeSuccess, bytes memory maxFeeData) = address(USDTContract).staticcall(
            abi.encodeWithSignature("maximumFee()")
        );
        require(maxFeeSuccess, "Failed to get USDT maximum fee");
        uint256 maximumFee = abi.decode(maxFeeData, (uint256));
        
        // Calculate fee
        uint256 fee = (baseCost * basisPointsRate) / 10000;
        if (fee > maximumFee && maximumFee > 0) {
            fee = maximumFee;
        }
        
        additionalCost = baseCost + fee;
    
				}
                require(
    USDTContract.balanceOf(msg.sender) >= additionalCost,
    "Insufficient USDT balance"
);
                require(
                 USDTContract.allowance(msg.sender, address(this)) >= additionalCost,
                   "Insufficient USDT allowance for price change"  
                );
                //USDTContract.transferFrom(msg.sender, address(escrowHandler), additionalCost);
                (bool success, bytes memory data) = address(USDTContract).call(
    abi.encodeWithSelector(
        ITether.transferFrom.selector,
        msg.sender,
        address(escrowHandler),
        additionalCost
    )
);
require(success, string(data));
            }

            // Call the EscrowHandler to update the order price
            usdtOrders.changeBuyOrderPriceUSDT(msg.sender, orderID, newPrice);
            break;
        }
    }
}*/
      function changeBuyOrderPriceUSDT(uint256 orderID, uint256 newPrice) public nonReentrant whenNotPaused {
    //require(newPrice >= central.LMEprice(), "Order price must be at least the current LME price");
    // Retrieve all buy orders in USDT
    SharedStructs.Order[] memory buyOrders = usdtOrders.getBuyOrdersUSDT();
    
    // Iterate through the buy orders to find the one with the matching ID
    for (uint256 i = 0; i < buyOrders.length; i++) {
        if (buyOrders[i].orderID == orderID) {
            // Ensure only the owner of the order can change the price
            require(buyOrders[i].user == msg.sender, "Only the owner can change the price");

            uint256 remainingAmount = buyOrders[i].amount;
            uint256 oldCost = (buyOrders[i].price * remainingAmount) / 1000;
            uint256 newCost = (newPrice * remainingAmount) / 1000;

            // Handle additional cost if the new price is higher
            if (newCost > oldCost) {
	  uint256 additionalCost;
	  {
                uint256 baseCost = newCost - oldCost;
        
        // Get fee parameters
       uint256 basisPointsRate = USDTContract.basisPointsRate();
       uint256 maximumFee = USDTContract.maximumFee();
       uint256 fee = 0;
    
    if (basisPointsRate > 0) {
        
        // First approximation
        additionalCost = (baseCost * 10000) / (10000 - basisPointsRate);
        
        // Adjust for exact match with USDT's calculation
        fee = (additionalCost * basisPointsRate) / 10000;
        if (maximumFee > 0 && fee > maximumFee) {
            fee = maximumFee;
        }
        
        // Recalculate additionalCost to ensure escrow gets EXACTLY baseCost
        additionalCost = baseCost + fee;
    } else {
        additionalCost = baseCost;
    }
				}
                require(
    USDTContract.balanceOf(msg.sender) >= additionalCost,
    "Insufficient USDT balance"
);
                require(
                 USDTContract.allowance(msg.sender, address(this)) >= additionalCost,
                   "Insufficient USDT allowance for price change"  
                );
                //USDTContract.transferFrom(msg.sender, address(escrowHandler), additionalCost);
                (bool success, bytes memory data) = address(USDTContract).call(
    abi.encodeWithSelector(
        ITether.transferFrom.selector,
        msg.sender,
        address(escrowHandler),
        additionalCost
    )
);
require(success, string(data));
            }

            // Call the EscrowHandler to update the order price
            usdtOrders.changeBuyOrderPriceUSDT(msg.sender, orderID, newPrice);
            break;
        }
    }
}
           
           function changeBuyOrderPriceUSDC(uint256 orderID, uint256 newPrice) public nonReentrant whenNotPaused {
   // require(newPrice >= central.LMEprice(), "Order price must be at least the current LME price");
    // Retrieve all buy orders in USDT
    SharedStructs.Order[] memory buyOrders = usdcOrders.getBuyOrdersUSDC();
    
    // Iterate through the buy orders to find the one with the matching ID
    for (uint256 i = 0; i < buyOrders.length; i++) {
        if (buyOrders[i].orderID == orderID) {
            // Ensure only the owner of the order can change the price
            require(buyOrders[i].user == msg.sender, "Only the owner can change the price");

            uint256 remainingAmount = buyOrders[i].amount;
            uint256 oldCost = (buyOrders[i].price * remainingAmount) / 1000;
            uint256 newCost = (newPrice * remainingAmount) / 1000;

            // Handle additional cost if the new price is higher
            if (newCost > oldCost) {
                uint256 additionalCost = newCost - oldCost;
                require(
                    USDCContract.allowance(msg.sender, address(this)) >= additionalCost,
                    "Insufficient USDT allowance for price change"
                );
                USDCContract.transferFrom(msg.sender, address(escrowHandler), additionalCost);
            }

            // Call the EscrowHandler to update the order price
            usdcOrders.changeBuyOrderPriceUSDC(msg.sender, orderID, newPrice);
            break;
        }
    }
}

       

    function changeSellOrderPriceEther(uint256 orderID, uint256 newPrice) public nonReentrant whenNotPaused {
        escrowHandler.changeSellOrderPriceEther(msg.sender, orderID, newPrice);
    }

    function changeSellOrderPriceUSDT(uint256 orderID, uint256 newPrice) public nonReentrant whenNotPaused {
        usdtOrders.changeSellOrderPriceUSDT(msg.sender, orderID, newPrice);
    }

    function changeSellOrderPriceUSDC(uint256 orderID, uint256 newPrice) public nonReentrant whenNotPaused {
        usdcOrders.changeSellOrderPriceUSDC(msg.sender, orderID, newPrice);
    }
    
    
    function getNickeliumBalance(address account) public view returns (uint256) {
    return balanceOf(account);
    }
    
    //With this the users can remove their orders at once.
    function removeAllOrders() public nonReentrant {
        adminControlContract.adminControl(msg.sender);
    }
  
    //Only admins can pause the contract for example for technical reasons.
    function pause() external whenNotPaused onlyAuthorized nonReentrant {
        _pause();
    }

    function unpause() external onlyAuthorized nonReentrant {
        _unpause();
    }

    }