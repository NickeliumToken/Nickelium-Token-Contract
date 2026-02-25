// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./SharedStructs.sol"; // Only import what's necessary for structs

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