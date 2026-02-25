
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
// File: @openzeppelin/contracts/token/ERC20/IERC20.sol


// OpenZeppelin Contracts (last updated v5.4.0) (token/ERC20/IERC20.sol)

pragma solidity >=0.4.16;

/**
 * @dev Interface of the ERC-20 standard as defined in the ERC.
 */
interface IERC20 {
    /**
     * @dev Emitted when `value` tokens are moved from one account (`from`) to
     * another (`to`).
     *
     * Note that `value` may be zero.
     */
    event Transfer(address indexed from, address indexed to, uint256 value);

    /**
     * @dev Emitted when the allowance of a `spender` for an `owner` is set by
     * a call to {approve}. `value` is the new allowance.
     */
    event Approval(address indexed owner, address indexed spender, uint256 value);

    /**
     * @dev Returns the value of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the value of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves a `value` amount of tokens from the caller's account to `to`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address to, uint256 value) external returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender) external view returns (uint256);

    /**
     * @dev Sets a `value` amount of tokens as the allowance of `spender` over the
     * caller's tokens.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * IMPORTANT: Beware that changing an allowance with this method brings the risk
     * that someone may use both the old and the new allowance by unfortunate
     * transaction ordering. One possible solution to mitigate this race
     * condition is to first reduce the spender's allowance to 0 and set the
     * desired value afterwards:
     * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
     *
     * Emits an {Approval} event.
     */
    function approve(address spender, uint256 value) external returns (bool);

    /**
     * @dev Moves a `value` amount of tokens from `from` to `to` using the
     * allowance mechanism. `value` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(address from, address to, uint256 value) external returns (bool);
}

// File: contracts/NickelType.sol


pragma solidity ^0.8.0;

enum NickelType { Land, Sea, Financial }
// File: contracts/INickelium.sol



pragma solidity ^0.8.0;

interface INickelium {
    
    function decimals() external view returns (uint8);

    function setAuthorizedAddress(address _address, bool _status) external;

    function setContracts(
        address _centralAddress,
        address _escrowHandlerAddress,
        address _adminControlAddress,
        address _usdtAddress,
        address _usdcAddress,
        address _usdcOrdersAddress,
        address _balancesContract,
        address _adminMultisig
    ) external;

    function addNickelToStock(uint256 amountGrams, NickelType nickelType) external;

    function mint(address account, uint256 TokenUnits) external;

    function burn(uint256 amount) external;

    function getAvailableNickeliumStock() external view returns (uint256);

    function checkNickeliumBalance(address account) external view returns (uint256);

    function approve(address spender, uint256 amount) external returns (bool);

    function approveToken(address user, address spender, uint256 amount) external returns (bool);

    function allowance(address owner, address spender) external view returns (uint256);

    function balanceOf(address account) external view returns (uint256);

    function transfer(address _to, uint256 amount) external returns (bool);

    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

    function transferFromContract(address recipient, uint256 amount) external;

    function getContractBalanceEther() external view returns (uint256);

    function placeBuyOrderEther(uint256 _price, uint256 _amount) external payable;

    function placeBuyOrderUSDT(uint256 _price, uint256 _amount) external;

    function placeBuyOrderUSDC(uint256 _price, uint256 _amount) external;

    function placeSellOrderEther(uint256 _price, uint256 _amount) external;

    function placeSellOrderUSDT(uint256 _price, uint256 _amount) external;

    function placeSellOrderUSDC(uint256 _price, uint256 _amount) external;

    function RemoveOrder(uint256 orderID) external;

    function changeBuyOrderPriceEther(uint256 orderID, uint256 newPrice) external payable;

    function changeBuyOrderPriceUSDT(uint256 orderID, uint256 newPrice) external;

    function changeBuyOrderPriceUSDC(uint256 orderID, uint256 newPrice) external;

    function changeSellOrderPriceEther(uint256 orderID, uint256 newPrice) external;

    function changeSellOrderPriceUSDT(uint256 orderID, uint256 newPrice) external;

    function changeSellOrderPriceUSDC(uint256 orderID, uint256 newPrice) external;

    function getNickeliumBalance(address account) external view returns (uint256);

    function removeAllOrders() external;

    function totalSupply() external view returns (uint256);

    function pause() external;

    function unpause() external;
}

// File: contracts/IAdminControl.sol


pragma solidity ^0.8.0;

interface IAdminControl {
    function matchOrders() external;
    function adminControl(address _user) external;
    function userRemoveOrder(address sender, uint256 orderID) external; 
    function pause() external ;
    function unpause() external;
    function setContracts( address _escrowHandler, address _USDTAddress, address _nickeliumAddress, address _multisig, address _facade ) external;

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

// File: contracts/ICentral.sol



pragma solidity ^0.8.0;


interface ICentral is IERC20 {
  function approveToken(address user, address spender, uint256 amount) external returns (bool);
  function setAuthorizedBuyer(address buyer, bool _status) external;
  function isAuthorizedBuyer(address buyer) external view returns (bool);
  function transferFromUser(address from, address to, uint256 amount) external returns (bool);
  function sendEther(address payable recipient) external payable;
  function releaseEther(address payable seller, uint amount) external;
  function revertEther(address sender, uint amount) external;
  function transfer(address _to, uint256 _value) external override returns (bool);
  function getNextOrderID() external returns (uint256);
  function setContracts( address _USDTAddress, address _escrowHandler, address _adminControl, address _balancesContract, address _multisig) external;
   function decimals() external view returns (uint8);
    function addNickeliumToStock(uint256 amountGrams) external;
    function getAvailableNickeliumStock() external returns(uint);
    function getContractBalanceEther() external view returns (uint);
    function placeBuyOrderEther(address buyer, uint256 _price, uint256 _amount) external payable ;
    function placeBuyOrderUSDT(address buyer, uint256 _price, uint256 _amount)  external payable;
    function placeBuyOrderUSDC(address buyer, uint256 _price, uint256 _amount) external payable;
    function placeSellOrderEther(address seller, uint256 _price, uint256 _amount) external payable ;
    function placeSellOrderUSDT(address seller, uint256 _price, uint256 _amount) external payable ;
    function placeSellOrderUSDC(address seller, uint256 _price, uint256 _amount) external payable ;
    function getEtherBalance(address account) external view returns (uint);
    function checkNickeliumBalance(address account) external view returns (uint256);
    function transferFromContract(address recipient, uint256 amount) external;
    function totalNickeliumInStock() external view returns (uint256);
    function LMEprice() external view returns (uint256);
    function LMEpriceInEther() external view returns (uint256);
    function feePercentage() external view returns (uint256);
    function usdtPerEth() external view returns (uint256);
}

// File: contracts/IOrderRouter.sol


pragma solidity ^0.8.0;


interface IOrderRouter {
    // State variables (as view functions)
    function escrowHandler() external view returns (address);
    function usdtOrders() external view returns (address);
    function usdcOrders() external view returns (address);

    // Buy order routing
    function routeBuyOrder(
        uint256 _orderID,
        address buyer,
        uint256 _price,
        uint256 _amount,
        SharedStructs.AssetType _assetType,
        SharedStructs.PaymentMethod _priceCurrency,
        bool authorizedBuyersOnly
    ) external;

    // Sell order routing
    function routeSellOrder(
        uint256 _orderID,
        address seller,
        uint256 _price,
        uint256 _amount,
        SharedStructs.AssetType _assetType,
        SharedStructs.PaymentMethod _priceCurrency,
        bool authorizedBuyersOnly
    ) external;
}
// File: contracts/ITether.sol


pragma solidity ^0.8.30;

interface ITether {
    // Standard ERC20 (with non-standard implementation)
    function transfer(address _to, uint _value) external;
    function transferFrom(address _from, address _to, uint _value) external;
    function balanceOf(address _owner) external view returns (uint);
    function approve(address _spender, uint _value) external;
    function allowance(address _owner, address _spender) external view returns (uint);
    
    // USDT-Specific Functions
    function basisPointsRate() external view returns (uint);
    function maximumFee() external view returns (uint);
    function paused() external view returns (bool);
    function isBlackListed(address _maker) external view returns (bool);
    function decimals() external view returns (uint8);
    
    // Events
    event Transfer(address indexed from, address indexed to, uint value);
    event Approval(address indexed owner, address indexed spender, uint value);
    event Issue(uint amount);
    event Redeem(uint amount);
    event Deprecate(address newAddress);
    event Params(uint feeBasisPoints, uint maxFee);
    event AddedBlackList(address _user);
    event RemovedBlackList(address _user);
    event DestroyedBlackFunds(address _blackListedUser, uint _balance);
}
// File: contracts/CustomMultisig.sol



pragma solidity ^0.8.0;

interface INFTContract {
    // Existing function
    function upgradeNFT(string memory name) external payable;

    // New functions
    function increaseUsedStock(uint256 amount) external;
    function setStockLimit(uint256 newLimit) external;
}











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
