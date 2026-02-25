/* SPDX-License-Identifier: Custom-License
*This contract is property of Destrier LLC. You are granted permission to use all functions of this contract intended for users. 
*However, copying, modifying, or distributing the code is strictly prohibited without explicit permission from the author.
*All rights reserved. Destrier LLC, registration number 20241316871 , Colorado , USA.*/
pragma solidity ^0.8.0;

interface ICentral {
    function dailyPrice() external view returns (uint256);
}

import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "./SharedStructs.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "./INickelium.sol";
import "./ITether.sol";

contract Mine1_NFT is ERC721Enumerable, ReentrancyGuard, Pausable {
    uint256 public currentTokenId;
    uint256 public nextTransferId = 0;
    address public owner;
    uint256 public landStock;
    uint256 public seaStock; 
    uint256 public financialStock;
    mapping(uint256 => uint256) public tokenValue; // Tracks the "value" of each NFT
    mapping(uint256 => string) public tokenName;   // Tracks the "name" of each NFT
    mapping(string => bool) public nameExists;     // Tracks if a name is taken
    mapping(address => bool) public authorizedAddresses;
    uint256[] public indexes; // Auxiliary array to store order IDs

    constructor() ERC721("Mine1_NFT", "NM1") {
        authorizedAddresses[msg.sender] = true;
        currentTokenId = 1;
    }

     using SharedStructs for SharedStructs.PaymentMethod;
     mapping(uint256 => TransferStatus) public transferStatus;
     mapping(uint256 => TransferStatusNickelium) public transferStatusNickelium;
     address public owner1;
    address public owner2;
    bool public isConfirmedByOwner1;
    bool public isConfirmedByOwner2;
     ITether public USDTContract;
     IERC20 public USDCContract;
    INickelium public nickeliumContract;
    ICentral public central;

    function setOwner(address newOwner) public onlyAuthorized {
        owner = newOwner;
    }

    function setContracts(
        address _centralAddress,
        address payable _nickeliumAddress,
        address _USDTAddress,
        address _usdcAddress
    ) external onlyAuthorized nonReentrant whenNotPaused {
        address payable payableCentralAddress = payable(_centralAddress);
        central = ICentral(payableCentralAddress);
        // Set Nickelium and its interface
        nickeliumContract = INickelium(_nickeliumAddress);

        // Set USDTContract
        USDTContract = ITether(_USDTAddress);

        // Set USDCContract and address
    USDCContract = IERC20(_usdcAddress); 
    }

    function GetNickelDailyPrice() public view returns (uint256 dailyPrice) {
    dailyPrice = central.dailyPrice();
    }

    uint256 public usedStock;
    uint256 public stockLimit;

     // Event to log when usedStock is increased
    event UsedStockIncreased(uint256 newUsedStock);

    // Event to log when stockLimit is set
    event StockLimitSet(uint256 newStockLimit);

    // Function to increase usedStock (can be called by other contracts)
    /*function increaseUsedStock(uint256 amount) external onlyAuthorized {
        require(usedStock + amount <= stockLimit, "Exceeds stock limit");
        usedStock += amount;
        emit UsedStockIncreased(usedStock);
    }*/
    function increaseUsedStock(uint256 amount, NickelType nickelType) external onlyAuthorized {
    require(usedStock + amount <= stockLimit, "Exceeds stock limit");
    
    // Update the specific nickel type based on selection
    if (nickelType == NickelType.Land) {
        landStock += amount;
    } else if (nickelType == NickelType.Sea) {
        seaStock += amount;
    } else if (nickelType == NickelType.Financial) {
        financialStock += amount;
    }
    
    usedStock += amount;
    emit UsedStockIncreased(usedStock);
}

// Optional: Add getter functions for individual stock types
function getStockByType(NickelType nickelType) external view returns (uint256) {
    if (nickelType == NickelType.Land) {
        return landStock;
    } else if (nickelType == NickelType.Sea) {
        return seaStock;
    } else {
        return financialStock;
    }
}

    // Function to set stockLimit (only owner can call this)
    function setStockLimit(uint256 newLimit) external onlyAuthorized {
        require(newLimit >= usedStock, "New limit must be >= used stock");
        stockLimit = newLimit;
        emit StockLimitSet(newLimit);
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

    function setAuthorizedAddress(address _address, bool _status) public onlyAuthorized nonReentrant whenNotPaused{
        authorizedAddresses[_address] = _status;
    }

    modifier onlyAuthorized() {
        require(authorizedAddresses[msg.sender], "Not authorized");
        _;
    }

    function setOwners(address _owner1, address _owner2) external onlyAuthorized nonReentrant whenNotPaused{
        owner1 = _owner1;
        owner2 = _owner2;
    }

     modifier onlyOwners() {
        require(msg.sender == owner1 || msg.sender == owner2, "Not an owner");
        _;
    }

    // Buy/upgrade an NFT by paying Ether
    function upgradeNFT(string memory name) external payable onlyAuthorized {
       // require(msg.value == 1 ether, "Invalid amount");
        uint256 totalValue = msg.value; // Initialize with the new payment

        if (nameExists[name]) {
            // Check if the payer owns an NFT with the specified name
            bool ownsNFTWithName = false;
            uint256 oldTokenId;

            for (uint256 i = 0; i < balanceOf(msg.sender); i++) {
                uint256 tokenId = tokenOfOwnerByIndex(msg.sender, i);
                if (keccak256(abi.encodePacked(tokenName[tokenId])) == keccak256(abi.encodePacked(name))) {
                    ownsNFTWithName = true;
                    oldTokenId = tokenId;
                    break;
                }
            }

            require(ownsNFTWithName, "You do not own an NFT with this name");

            // Burn the old NFT and fetch its value
            totalValue += tokenValue[oldTokenId]; // Add the old NFT's value
            _burn(oldTokenId); // Burn the old NFT
            nameExists[tokenName[oldTokenId]] = false; // Mark old name as available
        }
        // Mint a new NFT with the accumulated value
        _mint(msg.sender, currentTokenId);
        tokenValue[currentTokenId] = totalValue; // Set the total value
        tokenName[currentTokenId] = name;
        nameExists[name] = true; // Mark new name as taken

        currentTokenId++;
    }

    function getNFTsByOwner(address owner) external view returns (
    uint256[] memory ids,
    string[] memory names,
    uint256[] memory values
) {
    uint256 ownerBalance = balanceOf(owner);
    ids = new uint256[](ownerBalance);
    names = new string[](ownerBalance);
    values = new uint256[](ownerBalance);

    for (uint256 i = 0; i < ownerBalance; i++) {
        uint256 tokenId = tokenOfOwnerByIndex(owner, i);
        ids[i] = tokenId;
        names[i] = tokenName[tokenId];
        values[i] = tokenValue[tokenId];
    }

    return (ids, names, values);
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

    // Helper function to get the token ID of an NFT owned by an address
    function tokenOfOwnerByIndex(address owner, uint256 index) public view override returns (uint256) {
        return super.tokenOfOwnerByIndex(owner, index);
    }

    function emergencyStop() public onlyOwners nonReentrant whenNotPaused {
           _pause();
    }

    function resume() public onlyOwners nonReentrant {
               _unpause();
    }

   
}
