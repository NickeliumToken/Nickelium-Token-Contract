/* SPDX-License-Identifier: Custom-License
*This contract is property of Destrier LLC. You are granted permission to use all functions of this contract intended for users. 
*However, copying, modifying, or distributing the code is strictly prohibited without explicit permission from the author.
*All rights reserved. Destrier LLC, registration number 20241316871 , Colorado , USA.*/

pragma solidity ^0.8.0;
import "./SharedStructs.sol";
interface ICustomMultisig {
    struct TransferStatus {
        bool isConfirmedByOwner1;
        bool isConfirmedByOwner2;
        uint256 amount;
        address recipientAddress;
        address tokenAddress;
        uint256 orderID;
    }
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
    }
    enum ActionType { AddNickeliumToStock, Mint, Burn }
    struct Action {
        ActionType actionType;
        uint256 amountGrams; // Used for AddNickeliumToStock
        address account; // Used for Mint
        uint256 tokenUnits; // Used for Mint
        uint256 burnAmount; // Used for Burn
        address tokenOwner; // Used for Burn
        bool isConfirmedByOwner1;
        bool isConfirmedByOwner2;
    }
              function setOwners(address _owner1, address _owner2) external ;
              function setAuthorizedAddress(address _address, bool _status) external;
              function setContracts( address payable _nickeliumAddress, address _USDTAddress, address _escrowHandler, address _adminControlAddress ) external ;
              function getAvailableNickeliumStock() external view returns (uint256) ;
              function sendEther(address payable recipient) external payable ;
              function RemoveAllOrders (address _user) external ;
              function proposeAddNickeliumToStock(uint256 amountGrams) external ;
              function proposeMint(address account, uint256 tokenUnits) external ;
              function proposeBurn(uint256 amount, address tokenOwner) external ;
              function confirmAction(uint256 actionId) external ;
              function approveSpendingUSDT(address spender, uint256 amount) external ;
              function CreateBuyOrderEther (uint256 _price, uint256 _amount) external ;
              function CreateBuyOrderUSDT(uint256 _price, uint256 _amount) external ;
              function CreateSellOrderEther(uint256 _price,uint256 _amount) external ;
              function CreateSellOrderUSDT(uint256 _price,uint256 _amount) external ;
              function confirmOrder(uint256 _orderID) external ;
              function confirmTransfer(uint256 _orderID) external ;
              function CancelConfirmTransfer(uint256 _orderID) external ;
              function createTransfer(address _recipientAddress, uint256 _amount) external ;
              function executeTransfer(uint256 _orderID) external ;
              function DisplayTransferDetails(uint256 _orderID) external view returns (
              bool ConfirmedByOwner1,
              bool ConfirmedByOwner2,
              uint256 amount,
              address recipientAddress,
              uint256 orderID) ;
              function DisplayAllTransfers() external view returns (TransferStatus[] memory);
              function deleteTransfer(uint256 _orderID) external ;
              function cancelConfirmOrder(uint256 _orderID) external ;
              function executeOrder(uint256 _orderID) external payable ;
              function DisplayNextOrder() external view returns (PendingOrder memory) ;
              function DisplayAllOrders() external view returns (PendingOrder[] memory orders);
              function ShowOrderByID(uint256 _index) external view returns (PendingOrder memory);
              function ShowOrderByIndex2(uint256 _index) external view returns (PendingOrder memory);
              function deletePendingOrder(uint256 _orderID) external ;
              function removeOrder(uint256 orderID) external ;
              function getPendingActions() external view returns (uint256[] memory);
              function getActionDetails(uint256 actionId) external view returns (Action memory);
              function emergencyStop() external ;
              function resume() external ;
              function transferUSDT(address _to, uint256 _amount) external ;


}