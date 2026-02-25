/* SPDX-License-Identifier: Custom-License
*This contract is property of Destrier LLC. You are granted permission to use all functions of this contract intended for users. 
*However, copying, modifying, or distributing the code is strictly prohibited without explicit permission from the author.
*All rights reserved. Destrier LLC, registration number 20241316871 , Colorado , USA.*/

pragma solidity ^0.8.0;


import "./SharedStructs.sol";
import "./ICentral.sol";
import "./IEscrowHandler.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/math/Math.sol";
import "./IUSDCorders.sol";
import "./IUSDTorders.sol";
import "./INickelium.sol";
import "./ITether.sol";


contract AdminControl is Pausable, ReentrancyGuard {
    IEscrowHandler public escrowHandler; // Reference to MainContract
    ICentral public centralContract;
    ITether public USDTContract;
    IERC20 public USDCContract;
    INickelium public nickeliumContract;
    address public usdcContractAddress;
    IUSDCorders public usdcOrders;
    IUSDTorders public usdtOrders;
    mapping(address => bool) public authorizedAddresses;
    address public multisig;
    address public owner;
            
    constructor() {
              authorizedAddresses[msg.sender] = true;
    }

    modifier onlyMultisig() {
        require(msg.sender == multisig, "Only the multisig contract can call this function");
        _;
    }

    modifier onlyAuthorized() {
        require(authorizedAddresses[msg.sender], "Not authorized");
        _;
    }

    function setAuthorizedAddress(address _address, bool _status) public onlyAuthorized nonReentrant whenNotPaused {
        authorizedAddresses[_address] = _status;
    }

     function setContracts(
        address _escrowHandler,
        address _USDTAddress,
        address _usdcAddress,
        address _usdcOrdersAddress,
        address _usdtOrdersAddress,
        address _centralAddress,
        address _multisig,
        address _nickeliumAddress
    ) public onlyAuthorized nonReentrant whenNotPaused {
        escrowHandler = IEscrowHandler(_escrowHandler);
        USDTContract = ITether(_USDTAddress);
        USDCContract = IERC20(_usdcAddress);  
        usdcContractAddress = _usdcAddress;   
        usdcOrders = IUSDCorders(_usdcOrdersAddress);
        usdtOrders = IUSDTorders(_usdtOrdersAddress);
        centralContract = ICentral(_centralAddress);
        nickeliumContract = INickelium(_nickeliumAddress);
        multisig = _multisig;
    }
    
    function setOwner(address newOwner) public onlyAuthorized {
        owner = newOwner;
    }

    function adminControl(address _user) external nonReentrant onlyAuthorized {
               // Check if the user has any Nickelium balance
        if (escrowHandler.getAssetBalance(_user, SharedStructs.AssetType.Nickelium) > 0) {
            // Nickelium Escrow
            uint256 nickeliumEscrowBalance = escrowHandler.getAssetBalance(_user, SharedStructs.AssetType.Nickelium);
            if (nickeliumEscrowBalance > 0) {
                nickeliumContract.transferFromContract(_user, nickeliumEscrowBalance);
                escrowHandler.setAssetBalance(_user, SharedStructs.AssetType.Nickelium, 0);
            }

            // Remove related sell orders
            for (uint i = escrowHandler.sellOrdersEtherLength(); i > 0; i--) {
                SharedStructs.Order memory order = escrowHandler.getSellOrdersEther(i-1);
                if (order.user == _user) {
                    escrowHandler.removeSellOrderEther(i - 1);
                }
            }

            for (uint i = usdtOrders.sellOrdersUSDTLength(); i > 0; i--) {
                SharedStructs.Order memory order = usdtOrders.getSellOrdersUSDT(i-1);
                if (order.user == _user) {
                    usdtOrders.removeSellOrderUSDT(i-1);
                }
            }

            for (uint i = usdcOrders.sellOrdersUSDCLength(); i > 0; i--) {
                SharedStructs.Order memory order = usdcOrders.getSellOrdersUSDC(i-1);
                if (order.user == _user) {
                    usdcOrders.removeSellOrderUSDC(i-1);
                }
            }
        } else {
            // Ether Escrow
            uint256 etherEscrowBalance = escrowHandler.escrowBalances(_user, SharedStructs.PaymentMethod.Ether);
            if (etherEscrowBalance > 0) {
                centralContract.revertEther(_user, etherEscrowBalance);
                escrowHandler.setEscrowBalance(_user, SharedStructs.PaymentMethod.Ether, 0);
            }

            // USDT Escrow
            uint256 usdtEscrowBalance = escrowHandler.escrowBalances(_user, SharedStructs.PaymentMethod.USDT);
            if (usdtEscrowBalance > 0) {
                escrowHandler.approveUSDT(usdtEscrowBalance);
                (bool success, bytes memory data) = address(USDTContract).call(
    abi.encodeWithSelector(
        ITether.transferFrom.selector,
        address(escrowHandler),
        _user,
        usdtEscrowBalance
    )
);
require(success, string(data));
               // USDTContract.transferFrom(address(escrowHandler), _user, usdtEscrowBalance);
                //USDTContract.transfer(_user, usdtEscrowBalance);
                escrowHandler.setEscrowBalance(_user, SharedStructs.PaymentMethod.USDT, 0);
            }

             // USDC Escrow
            uint256 usdcEscrowBalance = escrowHandler.escrowBalances(_user, SharedStructs.PaymentMethod.USDC);
            if (usdcEscrowBalance > 0) {
                escrowHandler.approveUSDC(usdcEscrowBalance);
                USDCContract.transferFrom(address(escrowHandler), _user, usdcEscrowBalance);
                escrowHandler.setEscrowBalance(_user, SharedStructs.PaymentMethod.USDC, 0);
            }

            // Remove related buy orders
            for (uint i = escrowHandler.buyOrdersEtherLength(); i > 0; i--) {
                if (escrowHandler.getBuyOrdersEther(i-1).user == _user) {
                    escrowHandler.removeBuyOrderEther(i-1);
                }
            }

            for (uint i = usdtOrders.buyOrdersUSDTLength(); i > 0; i--) {
                if (usdtOrders.getBuyOrdersUSDT(i-1).user == _user) {
                    usdtOrders.removeBuyOrderUSDT(i-1);
                }
            }

            for (uint i = usdcOrders.buyOrdersUSDCLength(); i > 0; i--) {
                if (usdcOrders.getBuyOrdersUSDC(i-1).user == _user) {
                    usdcOrders.removeBuyOrderUSDC(i-1);
                }
            }
        }
    }
    
    
    function pause() external onlyAuthorized whenNotPaused nonReentrant{
        _pause();
    }

    function unpause() external onlyAuthorized nonReentrant{
        _unpause();
    }

    function userRemoveOrder(address sender, uint256 orderID) external nonReentrant onlyAuthorized {
    
    // First check in Ether buy and sell orders
    if (!removeOrderFromList(sender, orderID, true, SharedStructs.PaymentMethod.Ether)) {
        if (!removeOrderFromList(sender, orderID, false, SharedStructs.PaymentMethod.Ether)) {
            
            // Then check in USDT buy and sell orders
            if (!removeOrderFromList(sender, orderID, true, SharedStructs.PaymentMethod.USDT)) {
                if (!removeOrderFromList(sender, orderID, false, SharedStructs.PaymentMethod.USDT)) {
                    
                    // Finally check in USDC buy and sell orders
                    if (!removeOrderFromList(sender, orderID, true, SharedStructs.PaymentMethod.USDC)) {
                        if (!removeOrderFromList(sender, orderID, false, SharedStructs.PaymentMethod.USDC)) {
                            // If not found in any list, revert
                            revert("Order not found");
                        }
                    }
                }
            }
        }
    }
}

         function removeOrderFromList(address sender, uint256 orderID, bool isBuyOrder, SharedStructs.PaymentMethod paymentMethod) internal returns (bool) {
    SharedStructs.Order[] memory orders;

    // Fetch buy/sell orders based on the payment method and order type (isBuyOrder)
    if (isBuyOrder) {
        if (paymentMethod == SharedStructs.PaymentMethod.Ether) {
            orders = escrowHandler.getBuyOrdersEther();
        } else if (paymentMethod == SharedStructs.PaymentMethod.USDT) {
            orders = usdtOrders.getBuyOrdersUSDT();
        } else if (paymentMethod == SharedStructs.PaymentMethod.USDC) {
            orders = usdcOrders.getBuyOrdersUSDC();
        }
    } else {
        if (paymentMethod == SharedStructs.PaymentMethod.Ether) {
            orders = escrowHandler.getSellOrdersEther();
        } else if (paymentMethod == SharedStructs.PaymentMethod.USDT) {
            orders = usdtOrders.getSellOrdersUSDT();
        } else if (paymentMethod == SharedStructs.PaymentMethod.USDC) {
            orders = usdcOrders.getSellOrdersUSDC();
        }
    }

    // Search for the order in the respective order list
    for (uint256 i = 0; i < orders.length; i++) {
        if (orders[i].orderID == orderID) {
            SharedStructs.Order memory orderToRemove = orders[i];
            address orderOwner = orderToRemove.user;
            require(orderOwner == sender, "Only the owner or the buyer/seller can remove the order");

            // Handle buy orders
            if (isBuyOrder) {
                uint256 remainingAmount = orderToRemove.amount;
                uint256 cost = (orderToRemove.price * remainingAmount) / 1000;
                uint256 escrowBalance = escrowHandler.getEscrowBalance(orderOwner, paymentMethod);
                uint256 transferAmount = escrowBalance < cost ? escrowBalance : cost;

                if (paymentMethod == SharedStructs.PaymentMethod.Ether) {
                    require(escrowBalance >= transferAmount, "Insufficient ether escrow balance");
                    centralContract.revertEther(orderOwner, transferAmount);
                } else if (paymentMethod == SharedStructs.PaymentMethod.USDT) {
                    escrowHandler.approveUSDT(transferAmount);
                    (bool success, bytes memory data) = address(USDTContract).call(
    abi.encodeWithSelector(
        ITether.transferFrom.selector,
        address(escrowHandler),
        orderOwner,
        transferAmount
    )
);
require(success, string(data));
                    //USDTContract.transferFrom(address(escrowHandler), orderOwner, transferAmount);
                } else if (paymentMethod == SharedStructs.PaymentMethod.USDC) {
                    escrowHandler.approveUSDC(transferAmount);
                    USDCContract.transferFrom(address(escrowHandler), orderOwner, transferAmount);
                }

                escrowHandler.updateEscrowBalance(orderOwner, paymentMethod, transferAmount, false);
            } else {  // Handle sell orders
                uint256 remainingAmount = orderToRemove.amount;
                uint256 assetEscrowBalance = escrowHandler.getAssetBalance(orderOwner, orderToRemove.assetType);
                uint256 assetTransferAmount = assetEscrowBalance < remainingAmount ? assetEscrowBalance : remainingAmount;
                require(assetEscrowBalance >= assetTransferAmount, "Insufficient token escrow balance");
                nickeliumContract.transferFromContract(orderOwner, assetTransferAmount);
                escrowHandler.setAssetBalance(orderOwner, orderToRemove.assetType, assetEscrowBalance - assetTransferAmount);
            }

            // Remove the order from the appropriate list
            if (isBuyOrder) {
                if (paymentMethod == SharedStructs.PaymentMethod.Ether) {
                    escrowHandler.removeBuyOrderEther(i);
                } else if (paymentMethod == SharedStructs.PaymentMethod.USDT) {
                    usdtOrders.removeBuyOrderUSDT(i);
                } else if (paymentMethod == SharedStructs.PaymentMethod.USDC) {
                    usdcOrders.removeBuyOrderUSDC(i);
                }
            } else {
                if (paymentMethod == SharedStructs.PaymentMethod.Ether) {
                    escrowHandler.removeSellOrderEther(i);
                } else if (paymentMethod == SharedStructs.PaymentMethod.USDT) {
                    usdtOrders.removeSellOrderUSDT(i);
                } else if (paymentMethod == SharedStructs.PaymentMethod.USDC) {
                    usdcOrders.removeSellOrderUSDC(i);
                }
            }

            return true; // Order found and removed
        }
    }
    return false; // Order not found in this list
}
        

       
}