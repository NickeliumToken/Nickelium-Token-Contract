/* SPDX-License-Identifier: Custom-License
*This contract is property of Destrier LLC. You are granted permission to use all functions of this contract intended for users. 
*However, copying, modifying, or distributing the code is strictly prohibited without explicit permission from the author.
*All rights reserved. Destrier LLC, registration number 20241316871 , Colorado , USA.*/

pragma solidity ^0.8.0;

import "./SharedStructs.sol";
import "./IEscrowHandler.sol";
import "./IUSDTorders.sol";
import "./IUSDCorders.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import "@openzeppelin/contracts/security/Pausable.sol";

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