// SPDX-License-Identifier: Custom-License
/*This contract is part of Nickelium Token Ecosystem and is property of Destrier LLC. You are granted permission to use all functions of this contract intended for users. 
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