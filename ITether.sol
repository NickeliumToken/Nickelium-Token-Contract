// SPDX-License-Identifier: MIT
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