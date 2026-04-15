// SPDX-License-Identifier: Custom-License
/*This contract is part of Nickelium Token Ecosystem and is property of Destrier LLC. You are granted permission to use all functions of this contract intended for users. 
*However, copying, modifying, or distributing the code is strictly prohibited without explicit permission from the author.
*All rights reserved. Destrier LLC, registration number 20241316871 , Colorado , USA.*/
pragma solidity ^0.8.0;

import "./SharedStructs.sol";

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