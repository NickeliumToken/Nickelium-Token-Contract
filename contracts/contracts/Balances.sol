// SPDX-License-Identifier: Custom-License
/*This contract is part of Nickelium Token Ecosystem and is property of Destrier LLC. You are granted permission to use all functions of this contract intended for users. 
*However, copying, modifying, or distributing the code is strictly prohibited without explicit permission from the author.
*All rights reserved. Destrier LLC, registration number 20241316871 , Colorado , USA.*/

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/utils/Pausable.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";

interface NewBalances {
    function setBalance(address user, uint256 balance) external;
    function updateBalance(address user, uint256 balance) external;
}
contract Balances is ReentrancyGuard, Pausable{
        mapping(address => bool) public authorizedAddresses;
    mapping(address => uint256) public balances;
    mapping(address => bool) public userExists;
    address[] public users;
    mapping(address => bool) public authorizedBuyersBackupMap;
    address[] public authorizedBuyersBackupList; 


    constructor() {
                authorizedAddresses[msg.sender] = true;
    }

        modifier onlyAuthorized() {
        require(authorizedAddresses[msg.sender], "Not authorized");
        _;
    }
    address public owner;
    function setOwner(address newOwner) public onlyAuthorized {
        owner = newOwner;
    }

    function setAuthorizedAddress(address _address, bool _status) public onlyAuthorized nonReentrant {
        authorizedAddresses[_address] = _status;
    }

    	// Function to add a user to the users list
    function addUser(address user) internal {
        users.push(user);
    }
    
    // Function to update the balance and add user if not exists
    function updateBalance(address user, uint256 balance) external onlyAuthorized {
        if (!userExists[user]) {
            addUser(user);
            userExists[user] = true;
        }
        balances[user] = balance;
    }

     // Function to set balance
    function setBalance(address user, uint256 balance) external onlyAuthorized nonReentrant {
        balances[user] = balance;
    }
    
    // Function to migrate data to a new contract
    function migrateBalances(address newContract) external onlyAuthorized nonReentrant {
        for (uint256 i = 0; i < users.length; i++) {
            address user = users[i];
            uint256 balance = balances[user];
            NewBalances(newContract).setBalance(user, balance);
        }
    }

    function getAllBalances() external view returns (address[] memory, uint256[] memory) {
    uint256 userCount = users.length;
    uint256[] memory userBalances = new uint256[](userCount);
    
    for (uint256 i = 0; i < userCount; i++) {
        userBalances[i] = balances[users[i]];
    }
    
    return (users, userBalances);
}

   function getAllUserBalances() external view returns (address[] memory, uint256[] memory) {
    uint256 userCount = users.length;
    address[] memory userAddresses = new address[](userCount);
    uint256[] memory userBalances = new uint256[](userCount);

    for (uint256 i = 0; i < userCount; i++) {
        userAddresses[i] = users[i];
        userBalances[i] = balances[users[i]];
    }

    return (userAddresses, userBalances);
    }

    function getBalance(address user) external view returns (uint256) {
        return balances[user];
    }

    function setAuthorizedBuyerBackup(address buyer, bool _status) external onlyAuthorized nonReentrant {
    require(buyer != address(0), "Buyer address cannot be zero");

    if (_status) {
        // If setting to true, add to mapping and array if not already present
        if (!authorizedBuyersBackupMap[buyer]) {
            authorizedBuyersBackupMap[buyer] = true;
            authorizedBuyersBackupList.push(buyer);
        }
    } else {
        // If setting to false, remove from mapping and array
        if (authorizedBuyersBackupMap[buyer]) {
            authorizedBuyersBackupMap[buyer] = false;
            for (uint256 i = 0; i < authorizedBuyersBackupList.length; i++) {
                if (authorizedBuyersBackupList[i] == buyer) {
                    authorizedBuyersBackupList[i] = authorizedBuyersBackupList[authorizedBuyersBackupList.length - 1];
                    authorizedBuyersBackupList.pop();
                    break;
                }
            }
        }
    }
}
           
function getAuthorizedBuyersCount() external view returns (uint256) {
    return authorizedBuyersBackupList.length;
}

function getAuthorizedBuyerAtIndex(uint256 index) external view returns (address) {
    require(index < authorizedBuyersBackupList.length, "Index out of bounds");
    return authorizedBuyersBackupList[index];
}

function isAuthorizedBuyer(address buyer) external view returns (bool) {
    return authorizedBuyersBackupMap[buyer];
}



    //Only admins can pause the contract for example for technical reasons.
    function pause() external whenNotPaused onlyAuthorized nonReentrant {
        _pause();
    }

    function unpause() external onlyAuthorized nonReentrant {
        _unpause();
    }

}
