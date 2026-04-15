// SPDX-License-Identifier: Custom-License
/*This contract is part of Nickelium Token Ecosystem and is property of Destrier LLC. You are granted permission to use all functions of this contract intended for users. 
*However, copying, modifying, or distributing the code is strictly prohibited without explicit permission from the author.
*All rights reserved. Destrier LLC, registration number 20241316871 , Colorado , USA.*/
pragma solidity ^0.8.0;

import "./SharedStructs.sol";
import "./ICentral.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/Pausable.sol";
import "./ITether.sol";
import "./INickelium.sol";

interface IERC20WithDecimals is IERC20 {
    function decimals() external view returns (uint8);
}


contract TokenSale is Pausable, ReentrancyGuard {
     ITether public USDTContract;
     IERC20WithDecimals public USDCContract;
     INickelium public nickelium;
     INickelium public nickeliumContract;
     ICentral public centralContract;
     address public owner1;
    address public owner2;
    mapping(address => bool) public authorizedAddresses;
    uint256 public nextTransferId = 0;
    uint256[] public indexes; // Auxiliary array to store order IDs
    
    uint8 public constant TOKEN_DECIMALS = 3;
    uint8 public constant USDC_DECIMALS = 6;
    uint256 public constant TOKEN_DECIMAL_FACTOR = 10**3;
    uint256 public constant USDC_DECIMAL_FACTOR = 10**6;
    
    event OrderCreated(
        address indexed user,
        uint256 usdcAmount,
        uint256 feeInUSDC,
		uint256 pricePerToken,
        uint256 totalCost,
        uint256 tokenAmount, 
        bool isPositive,
        uint256 timestamp
    );
    
    event PurchaseCompleted(
        address indexed user,
        uint256 usdcAmount,
        uint256 feeInUSDC,
		uint256 pricePerToken,
        uint256 totalCost,
        uint256 tokenAmount,
        bool isPositive,
        uint256 timestamp
    );

    modifier onlyOwners() {
        require(msg.sender == owner1 || msg.sender == owner2, "Not an owner");
        _;
    }
    modifier onlyAuthorized() {
        require(authorizedAddresses[msg.sender], "Not authorized");
        _;
    }

    constructor() {
        authorizedAddresses[msg.sender] = true;
    }

    function setContracts(
        address payable _nickeliumAddress,
        address _centralAddress,
        address _USDTAddress,
        address _usdcAddress
    ) external onlyAuthorized nonReentrant whenNotPaused {
        // Set Nickelium and its interface
        nickeliumContract = INickelium(_nickeliumAddress);
        nickelium = INickelium(_nickeliumAddress);
        require(nickelium.decimals() == TOKEN_DECIMALS, "Token decimals mismatch");
        centralContract = ICentral(_centralAddress);
        // Set USDTContract
        USDTContract = ITether(_USDTAddress);
        // Set USDCContract and address
    USDCContract = IERC20WithDecimals(_usdcAddress); 
    require(USDCContract.decimals() == USDC_DECIMALS, "USDC decimals mismatch");
    }

    function setOwners(address _owner1, address _owner2) external onlyAuthorized nonReentrant whenNotPaused{
        owner1 = _owner1;
        owner2 = _owner2;
    }

    function createOrder(uint256 tokenAmount) external payable {
        require(tokenAmount <= 2000 * 10**3, "Maximum order amount is 2000 tokens"); // 2000 tokens with 3 decimals
        uint256 pricePerToken = centralContract.LMEprice(); // price with 6 decimals
        // tokenAmount is in 3 decimals, pricePerToken is in 6 decimals
        // usdcAmount = (tokenAmount * pricePerToken) / 10^3
        uint256 usdcAmount = (tokenAmount * pricePerToken) / TOKEN_DECIMAL_FACTOR;
            
     uint256 feeInUSDC = (usdcAmount * centralContract.feePercentage()) / 10000;
     uint256 totalCost = usdcAmount + feeInUSDC;
     // Convert USDC amount to ETH using the price from central contract
    uint256 ethForOneUSDC = (1e6 * 1e18) / centralContract.usdtPerEth();
    
    // Check if sent ETH matches 1 USDC worth
    require(msg.value == ethForOneUSDC, "Incorrect ETH amount sent - must equal 1 USDC");
        emit OrderCreated(
            msg.sender,
            usdcAmount,
            feeInUSDC,
			pricePerToken,
            totalCost,
            tokenAmount,
            true,  // positive - order created
            block.timestamp
        );
    }

    function completePurchase(uint256 usdcAmount) external nonReentrant {
        // Get current price (6 decimals)
        uint256 pricePerToken = centralContract.LMEprice();
        
        // Calculate token amount
        // usdcAmount is in 6 decimals, pricePerToken is in 6 decimals
        // tokenAmount = (usdcAmount * 10^3) / pricePerToken
        uint256 tokenAmount = (usdcAmount * TOKEN_DECIMAL_FACTOR) / pricePerToken;
        
        require(tokenAmount > 0, "Token amount too small");
        uint256 feeInUSDC = (usdcAmount * centralContract.feePercentage()) / 10000;
     uint256 totalCost = usdcAmount + feeInUSDC;


        // Check if user has approved enough USDC
        uint256 allowedUsdc = USDCContract.allowance(msg.sender, address(this));
        require(allowedUsdc >= totalCost, "Insufficient USDC allowance");
        
        // Check if contract has enough tokens to send to user
        uint256 contractTokenBalance = nickelium.balanceOf(address(this));
        require(contractTokenBalance >= tokenAmount, "Insufficient tokens in contract");
        
        // TRANSFER USDC FROM USER TO CONTRACT
        require(
            USDCContract.transferFrom(msg.sender, address(this), totalCost),
            "USDC transfer failed"
        );

        // TRANSFER TOKENS FROM CONTRACT TO USER
        require(
        nickelium.transfer(msg.sender, tokenAmount),
        "Token transfer failed"
    );

        // Emit purchase event (negative - order fulfilled)
        emit PurchaseCompleted(
            msg.sender,
            usdcAmount,
			feeInUSDC,
			pricePerToken,
            totalCost,
            tokenAmount,
            false,  // negative - order fulfilled/deducted
            block.timestamp
        );
    }

    // View functions with proper decimal handling
    function calculateTokenAmount(uint256 usdcAmount) external view returns (uint256) {
        uint256 pricePerToken = centralContract.LMEprice();
        uint256 tokenAmount = (usdcAmount * TOKEN_DECIMAL_FACTOR) / pricePerToken;
        return tokenAmount;
    }

    function calculateUsdcAmount(uint256 tokenAmount) external view returns (uint256) {
        uint256 pricePerToken = centralContract.LMEprice();
        uint256 usdcAmount = (tokenAmount * pricePerToken) / TOKEN_DECIMAL_FACTOR;
        return usdcAmount;
    }

    // Get current price in human-readable format (for frontend)
    function getPrice() external view returns (uint256) {
        return centralContract.LMEprice(); // Returns 6 decimal price
    }

    	
	struct TransferStatus {
        bool isConfirmedByOwner1;
        bool isConfirmedByOwner2;
        uint256 amount;
        address recipientAddress;
        SharedStructs.PaymentMethod paymentMethod;
        uint256 orderID;
    }

    struct TransferStatusNickelium {
        bool isConfirmedByOwner1;
        bool isConfirmedByOwner2;
        uint256 amount;
        address recipientAddress;
        SharedStructs.AssetType assetType;
        uint256 orderID;
    }

     mapping(uint256 => TransferStatus) public transferStatus;
    mapping(uint256 => TransferStatusNickelium) public transferStatusNickelium;

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


    function deleteTransfer(uint256 _transferID) public onlyOwners whenNotPaused {
    
    // Delete the data from the mappings
    delete transferStatus[_transferID];
    delete transferStatusNickelium[_transferID];

    // Remove the ID from the index array
    _removeTransferId(_transferID);
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
   function pause() public onlyAuthorized {
        _pause();
    }

    // Unpause the contract - only owner can call
    function unpause() public onlyAuthorized {
        _unpause();
    }
}