/* SPDX-License-Identifier: Custom-License
*This contract is property of Destrier LLC. You are granted permission to use all functions of this contract intended for users. 
*However, copying, modifying, or distributing the code is strictly prohibited without explicit permission from the author.
*All rights reserved. Destrier LLC, registration number 20241316871 , Colorado , USA.*/
pragma solidity ^0.8.0;

import "./SharedStructs.sol";

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
