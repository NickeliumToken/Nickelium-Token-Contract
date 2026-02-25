
// File: contracts/SharedStructs.sol

/* SPDX-License-Identifier: Custom-License
*This contract is property of Destrier LLC. You are granted permission to use all functions of this contract intended for users. 
*However, copying, modifying, or distributing the code is strictly prohibited without explicit permission from the author.
*All rights reserved. Destrier LLC, registration number 20241316871 , Colorado , USA.*/

pragma solidity ^0.8.0;
library SharedStructs {
    enum AssetType { Nickelium }
    enum PaymentMethod { Ether, USDT, USDC }

    struct Order {
        uint256 orderID;
        address payable user;
        uint256 price;
        uint256 amount;
        uint256 fulfilledAmount;
        AssetType assetType;
        PaymentMethod priceCurrency;
        bool authorizedBuyersOnly;
    }
   
}
// File: contracts/IEscrowHandler.sol


pragma solidity ^0.8.0;


interface IEscrowHandler {
    // State variables and mappings (as view functions)
    function assetBalances(address user, SharedStructs.AssetType assetType) external view returns (uint256);
    function escrowBalances(address user, SharedStructs.PaymentMethod method) external view returns (uint256);
    function authorizedAddresses(address user) external view returns (bool);
    function getAssetBalance(address user, SharedStructs.AssetType assetType) external view returns (uint256);
    function getEscrowBalance(address user, SharedStructs.PaymentMethod method) external view returns (uint256) ;
    // Order-related functions
    function buyOrdersEther(uint256 index) external view returns (SharedStructs.Order memory);
    function sellOrdersEther(uint256 index) external view returns (SharedStructs.Order memory);
    function getBuyOrdersEther() external view returns (SharedStructs.Order[] memory);
    function getBuyOrdersEther(uint index) external view returns (SharedStructs.Order memory);
    function getSellOrdersEther() external view returns (SharedStructs.Order[] memory);
    function getSellOrdersEther(uint index) external view returns (SharedStructs.Order memory);
    function sellOrdersEtherLength() external view returns (uint256);
    function buyOrdersEtherLength() external view returns (uint256);
    function getHighestBuyOrderEther() external view returns (SharedStructs.Order memory);
    function getLowestSellOrderEther() external view returns (SharedStructs.Order memory);

    // Authorization and ownership
    function setAuthorizedAddress(address _address, bool _status) external;
    function setOwner(address newOwner) external;

    // Contract setup
    function setContracts(
        address _centralAddress,
        address _USDTAddress,
        address _usdcAddress,
        address _nickeliumAddress,
        address _adminControl
    ) external;

    // Escrow and asset management
    function approveUSDT(uint256 transferAmount) external;
    function approveUSDC(uint256 transferAmount) external;
    function updateEscrowBalance(address user, SharedStructs.PaymentMethod method, uint256 cost, bool increase) external;
    function setAssetBalance(address _user, SharedStructs.AssetType _assetType, uint256 _amount) external;
    function setEscrowBalance(address _user, SharedStructs.PaymentMethod _paymentMethod, uint256 _amount) external;
    function transferFromAsset(address seller, address payable buyer, uint256 amount) external;

    // Order management
    function addBuyOrder(uint256 _orderID, address buyer, uint256 _price, uint256 _amount, SharedStructs.AssetType _assetType, SharedStructs.PaymentMethod _priceCurrency, bool authorizedBuyersOnly) external;
    function addSellOrder(uint256 _orderID, address seller, uint256 _price, uint256 _amount, SharedStructs.AssetType _assetType, SharedStructs.PaymentMethod _priceCurrency, bool authorizedBuyersOnly) external;
    function removeBuyOrderEther(uint256 index) external;
    function removeSellOrderEther(uint256 index) external;
    function changeBuyOrderPriceEther(address buyer, uint256 orderID, uint256 newPrice) external payable;
    function changeSellOrderPriceEther(address seller, uint256 orderID, uint256 newPrice) external;
    function updateOrderAmount(uint256 index, uint256 newAmount, bool isBuyOrder, bool isEther) external;

    // Pause and unpause
    function pause() external;
    function unpause() external;
}
// File: contracts/IUSDTorders.sol


pragma solidity ^0.8.0;


interface IUSDTorders {
    // State variables
    function authorizedAddresses(address _address) external view returns (bool);
    function owner() external view returns (address);
    function escrowHandler() external view returns (address);
    function USDTContract() external view returns (address);
    function nickeliumContract() external view returns (address);
    function adminControl() external view returns (address);
    function buyOrdersUSDT(uint256 index) external view returns (SharedStructs.Order memory);
    function sellOrdersUSDT(uint256 index) external view returns (SharedStructs.Order memory);
    function buyOrdersUSDTLength() external view returns (uint256);
    function sellOrdersUSDTLength() external view returns (uint256);

    // External functions
    function setAuthorizedAddress(address _address, bool _status) external;
    function setOwner(address newOwner) external;
    function setContracts(
        address _USDTAddress,
        address _nickeliumAddress,
        address _adminControl,
        address _escrowHandler
    ) external;
    function approveUSDT(address adminControlAddress, uint256 transferAmount) external;
    function getBuyOrdersUSDT() external view returns (SharedStructs.Order[] memory);
    function getBuyOrdersUSDT(uint index) external view returns (SharedStructs.Order memory);
    function getSellOrdersUSDT() external view returns (SharedStructs.Order[] memory);
    function getSellOrdersUSDT(uint index) external view returns (SharedStructs.Order memory);
    function getHighestBuyOrderUSDT() external view returns (SharedStructs.Order memory);
    function getLowestSellOrderUSDT() external view returns (SharedStructs.Order memory);
    function removeBuyOrderUSDT(uint256 index) external;
    function removeSellOrderUSDT(uint256 index) external;
    function addBuyOrder(
        uint256 _orderID,
        address buyer,
        uint256 _price,
        uint256 _amount,
        SharedStructs.AssetType _assetType,
        SharedStructs.PaymentMethod _priceCurrency,
        bool authorizedBuyersOnly
    ) external;
    function addSellOrder(
        uint256 _orderID,
        address seller,
        uint256 _price,
        uint256 _amount,
        SharedStructs.AssetType _assetType,
        SharedStructs.PaymentMethod _priceCurrency,
        bool authorizedBuyersOnly
    ) external;
    function changeBuyOrderPriceUSDT(address buyer, uint256 orderID, uint256 newPrice) external;
    function changeSellOrderPriceUSDT(address seller, uint256 orderID, uint256 newPrice) external;
    function pause() external;
    function unpause() external;
    function updateOrderAmount(uint256 index, uint256 newAmount, bool isBuyOrder, bool isUSDT) external;
}

// File: contracts/IUSDCorders.sol


pragma solidity ^0.8.0;


interface IUSDCorders {
    // State variables
    function authorizedAddresses(address _address) external view returns (bool);
    function owner() external view returns (address);
    function escrowHandler() external view returns (address);
    function USDCContract() external view returns (address);
    function nickeliumContract() external view returns (address);
    function adminControl() external view returns (address);
    function buyOrdersUSDC(uint256 index) external view returns (SharedStructs.Order memory);
    function sellOrdersUSDC(uint256 index) external view returns (SharedStructs.Order memory);
    function buyOrdersUSDCLength() external view returns (uint256);
    function sellOrdersUSDCLength() external view returns (uint256);

    // External functions
    function setAuthorizedAddress(address _address, bool _status) external;
    function setOwner(address newOwner) external;
    function setContracts(
        address _USDCAddress,
        address _nickeliumAddress,
        address _adminControl,
        address _escrowHandler
    ) external;
    function approveUSDC(address adminControlAddress, uint256 transferAmount) external;
    function getBuyOrdersUSDC() external view returns (SharedStructs.Order[] memory);
    function getBuyOrdersUSDC(uint index) external view returns (SharedStructs.Order memory);
    function getSellOrdersUSDC() external view returns (SharedStructs.Order[] memory);
    function getSellOrdersUSDC(uint index) external view returns (SharedStructs.Order memory);
    function getHighestBuyOrderUSDC() external view returns (SharedStructs.Order memory);
    function getLowestSellOrderUSDC() external view returns (SharedStructs.Order memory);
    function removeBuyOrderUSDC(uint256 index) external;
    function removeSellOrderUSDC(uint256 index) external;
    function addBuyOrder(
        uint256 _orderID,
        address buyer,
        uint256 _price,
        uint256 _amount,
        SharedStructs.AssetType _assetType,
        SharedStructs.PaymentMethod _priceCurrency,
        bool authorizedBuyersOnly
    ) external;
    function addSellOrder(
        uint256 _orderID,
        address seller,
        uint256 _price,
        uint256 _amount,
        SharedStructs.AssetType _assetType,
        SharedStructs.PaymentMethod _priceCurrency,
        bool authorizedBuyersOnly
    ) external;
    function changeBuyOrderPriceUSDC(address buyer, uint256 orderID, uint256 newPrice) external;
    function changeSellOrderPriceUSDC(address seller, uint256 orderID, uint256 newPrice) external;
    function pause() external;
    function unpause() external;
    function updateOrderAmount(uint256 index, uint256 newAmount, bool isBuyOrder, bool isUSDC) external;
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

// File: contracts/OrderRouter.sol



pragma solidity ^0.8.0;







contract OrderRouter is ReentrancyGuard, Pausable {
    IEscrowHandler public escrowHandler;
    IUSDTorders public usdtOrders;
    IUSDCorders public usdcOrders;
    mapping(address => bool) public authorizedAddresses;
    address public owner;

    constructor() {
        authorizedAddresses[msg.sender] = true;
    }

    modifier onlyAuthorized() {
        require(authorizedAddresses[msg.sender], "Not authorized");
        _;
    }

    function setAuthorizedAddress(address _address, bool _status) public onlyAuthorized nonReentrant whenNotPaused {
        authorizedAddresses[_address] = _status;
    }

    function setOwner(address newOwner) public onlyAuthorized {
        owner = newOwner;
    }

    function setContracts(
        address _escrowHandler,
        address _usdtOrders,
        address _usdcOrders
    ) external onlyAuthorized nonReentrant whenNotPaused {
        require(_escrowHandler != address(0), "Invalid escrowHandler address");
        require(_usdtOrders != address(0), "Invalid usdtOrders address");
        require(_usdcOrders != address(0), "Invalid usdcOrders address");

        escrowHandler = IEscrowHandler(_escrowHandler);
        usdtOrders = IUSDTorders(_usdtOrders);
        usdcOrders = IUSDCorders(_usdcOrders);
    }

    function routeBuyOrder(
        uint256 _orderID,
        address buyer,
        uint256 _price,
        uint256 _amount,
        SharedStructs.AssetType _assetType,
        SharedStructs.PaymentMethod _priceCurrency,
        bool authorizedBuyersOnly
    ) external onlyAuthorized nonReentrant whenNotPaused {
        if (_priceCurrency == SharedStructs.PaymentMethod.Ether) {
            escrowHandler.addBuyOrder(
                _orderID,
                buyer,
                _price,
                _amount,
                _assetType,
                _priceCurrency,
                authorizedBuyersOnly
            );
        } else if (_priceCurrency == SharedStructs.PaymentMethod.USDT) {
            usdtOrders.addBuyOrder(
                _orderID,
                buyer,
                _price,
                _amount,
                _assetType,
                _priceCurrency,
                authorizedBuyersOnly
            );
        } else if (_priceCurrency == SharedStructs.PaymentMethod.USDC) {
            usdcOrders.addBuyOrder(
                _orderID,
                buyer,
                _price,
                _amount,
                _assetType,
                _priceCurrency,
                authorizedBuyersOnly
            );
        } else {
            revert("Unsupported payment method");
        }
    }

    function routeSellOrder(
        uint256 _orderID,
        address seller,
        uint256 _price,
        uint256 _amount,
        SharedStructs.AssetType _assetType,
        SharedStructs.PaymentMethod _priceCurrency,
        bool authorizedBuyersOnly
    ) external onlyAuthorized nonReentrant whenNotPaused {
        if (_priceCurrency == SharedStructs.PaymentMethod.Ether) {
            escrowHandler.addSellOrder(
                _orderID,
                seller,
                _price,
                _amount,
                _assetType,
                _priceCurrency,
                authorizedBuyersOnly
            );
        } else if (_priceCurrency == SharedStructs.PaymentMethod.USDT) {
            usdtOrders.addSellOrder(
                _orderID,
                seller,
                _price,
                _amount,
                _assetType,
                _priceCurrency,
                authorizedBuyersOnly
            );
        } else if (_priceCurrency == SharedStructs.PaymentMethod.USDC) {
            usdcOrders.addSellOrder(
                _orderID,
                seller,
                _price,
                _amount,
                _assetType,
                _priceCurrency,
                authorizedBuyersOnly
            );
        } else {
            revert("Unsupported payment method");
        }
    }

    //Only admins can pause the contract for example for technical reasons.
    function pause() external whenNotPaused onlyAuthorized nonReentrant {
        _pause();
    }

    function unpause() external onlyAuthorized nonReentrant {
        _unpause();
    }
}