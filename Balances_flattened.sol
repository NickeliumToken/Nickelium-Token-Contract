
// File: @openzeppelin/contracts/utils/Context.sol


// OpenZeppelin Contracts (last updated v5.0.1) (utils/Context.sol)

pragma solidity ^0.8.20;

/**
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }

    function _contextSuffixLength() internal view virtual returns (uint256) {
        return 0;
    }
}

// File: @openzeppelin/contracts/security/Pausable.sol


// OpenZeppelin Contracts (last updated v4.7.0) (security/Pausable.sol)

pragma solidity ^0.8.0;


/**
 * @dev Contract module which allows children to implement an emergency stop
 * mechanism that can be triggered by an authorized account.
 *
 * This module is used through inheritance. It will make available the
 * modifiers `whenNotPaused` and `whenPaused`, which can be applied to
 * the functions of your contract. Note that they will not be pausable by
 * simply including this module, only once the modifiers are put in place.
 */
abstract contract Pausable is Context {
    /**
     * @dev Emitted when the pause is triggered by `account`.
     */
    event Paused(address account);

    /**
     * @dev Emitted when the pause is lifted by `account`.
     */
    event Unpaused(address account);

    bool private _paused;

    /**
     * @dev Initializes the contract in unpaused state.
     */
    constructor() {
        _paused = false;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is not paused.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    modifier whenNotPaused() {
        _requireNotPaused();
        _;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is paused.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    modifier whenPaused() {
        _requirePaused();
        _;
    }

    /**
     * @dev Returns true if the contract is paused, and false otherwise.
     */
    function paused() public view virtual returns (bool) {
        return _paused;
    }

    /**
     * @dev Throws if the contract is paused.
     */
    function _requireNotPaused() internal view virtual {
        require(!paused(), "Pausable: paused");
    }

    /**
     * @dev Throws if the contract is not paused.
     */
    function _requirePaused() internal view virtual {
        require(paused(), "Pausable: not paused");
    }

    /**
     * @dev Triggers stopped state.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    function _pause() internal virtual whenNotPaused {
        _paused = true;
        emit Paused(_msgSender());
    }

    /**
     * @dev Returns to normal state.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    function _unpause() internal virtual whenPaused {
        _paused = false;
        emit Unpaused(_msgSender());
    }
}

// File: @openzeppelin/contracts/utils/ReentrancyGuard.sol


// OpenZeppelin Contracts (last updated v5.1.0) (utils/ReentrancyGuard.sol)

pragma solidity ^0.8.20;

/**
 * @dev Contract module that helps prevent reentrant calls to a function.
 *
 * Inheriting from `ReentrancyGuard` will make the {nonReentrant} modifier
 * available, which can be applied to functions to make sure there are no nested
 * (reentrant) calls to them.
 *
 * Note that because there is a single `nonReentrant` guard, functions marked as
 * `nonReentrant` may not call one another. This can be worked around by making
 * those functions `private`, and then adding `external` `nonReentrant` entry
 * points to them.
 *
 * TIP: If EIP-1153 (transient storage) is available on the chain you're deploying at,
 * consider using {ReentrancyGuardTransient} instead.
 *
 * TIP: If you would like to learn more about reentrancy and alternative ways
 * to protect against it, check out our blog post
 * https://blog.openzeppelin.com/reentrancy-after-istanbul/[Reentrancy After Istanbul].
 */
abstract contract ReentrancyGuard {
    // Booleans are more expensive than uint256 or any type that takes up a full
    // word because each write operation emits an extra SLOAD to first read the
    // slot's contents, replace the bits taken up by the boolean, and then write
    // back. This is the compiler's defense against contract upgrades and
    // pointer aliasing, and it cannot be disabled.

    // The values being non-zero value makes deployment a bit more expensive,
    // but in exchange the refund on every call to nonReentrant will be lower in
    // amount. Since refunds are capped to a percentage of the total
    // transaction's gas, it is best to keep them low in cases like this one, to
    // increase the likelihood of the full refund coming into effect.
    uint256 private constant NOT_ENTERED = 1;
    uint256 private constant ENTERED = 2;

    uint256 private _status;

    /**
     * @dev Unauthorized reentrant call.
     */
    error ReentrancyGuardReentrantCall();

    constructor() {
        _status = NOT_ENTERED;
    }

    /**
     * @dev Prevents a contract from calling itself, directly or indirectly.
     * Calling a `nonReentrant` function from another `nonReentrant`
     * function is not supported. It is possible to prevent this from happening
     * by making the `nonReentrant` function external, and making it call a
     * `private` function that does the actual work.
     */
    modifier nonReentrant() {
        _nonReentrantBefore();
        _;
        _nonReentrantAfter();
    }

    function _nonReentrantBefore() private {
        // On the first call to nonReentrant, _status will be NOT_ENTERED
        if (_status == ENTERED) {
            revert ReentrancyGuardReentrantCall();
        }

        // Any calls to nonReentrant after this point will fail
        _status = ENTERED;
    }

    function _nonReentrantAfter() private {
        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _status = NOT_ENTERED;
    }

    /**
     * @dev Returns true if the reentrancy guard is currently set to "entered", which indicates there is a
     * `nonReentrant` function in the call stack.
     */
    function _reentrancyGuardEntered() internal view returns (bool) {
        return _status == ENTERED;
    }
}

// File: contracts/Balances.sol

/* SPDX-License-Identifier: Custom-License
*This contract is property of Destrier LLC. You are granted permission to use all functions of this contract intended for users. 
*However, copying, modifying, or distributing the code is strictly prohibited without explicit permission from the author.
*All rights reserved. Destrier LLC, registration number 20241316871 , Colorado , USA.*/

pragma solidity ^0.8.0;



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
