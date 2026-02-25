// SPDX-License-Identifier: Custom-License
pragma solidity ^0.8.0;

interface IBalances {
    // Function to set an authorized address
    function setAuthorizedAddress(address _address, bool _status) external;

    // Function to update the balance of a user
    function updateBalance(address user, uint256 balance) external;

    // Function to set the balance directly
    function setBalance(address user, uint256 balance) external;

    // Function to migrate balances to a new contract
    function migrateBalances(address newContract) external;

    // Function to get all balances
    function getAllBalances() external view returns (address[] memory, uint256[] memory);

    // Function to get all user balances
    function getAllUserBalances() external view returns (address[] memory, uint256[] memory);

    // Function to get the balance of a specific user
    function getBalance(address user) external view returns (uint256);

    function setAuthorizedBuyerBackup(address buyer, bool _status) external;

    function getAuthorizedBuyersCount() external view returns (uint256);

    function getAuthorizedBuyerAtIndex(uint256 index) external view returns (address);

    function isAuthorizedBuyer(address buyer) external view returns (bool);

    // Function to pause the contract
    function pause() external;

    // Function to unpause the contract
    function unpause() external;
}
