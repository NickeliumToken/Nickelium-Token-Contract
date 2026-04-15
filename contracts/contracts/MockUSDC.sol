// SPDX-License-Identifier: Custom-License
/*This contract is part of Nickelium Token Ecosystem and is property of Destrier LLC. You are granted permission to use all functions of this contract intended for users. 
*However, copying, modifying, or distributing the code is strictly prohibited without explicit permission from the author.
*All rights reserved. Destrier LLC, registration number 20241316871 , Colorado , USA.*/
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/Pausable.sol";

contract MockUSDC is ERC20, ReentrancyGuard, Pausable {
    mapping(address => bool) public authorizedAddresses;

    constructor() ERC20("Mock USDC", "mUSDC") {
        authorizedAddresses[msg.sender] = true;
    }

    // Override decimals to return 6
    function decimals() public pure override returns (uint8) {
        return 6;
    }

    modifier onlyAuthorized() {
        require(authorizedAddresses[msg.sender], "Not authorized");
        _;
    }

    function setAuthorizedAddress(address _address, bool _status) public onlyAuthorized nonReentrant whenNotPaused {
        authorizedAddresses[_address] = _status;
    }

    function mint(address to, uint256 amount) public onlyAuthorized nonReentrant whenNotPaused {
        _mint(to, amount);
    }

    function pause() external whenNotPaused onlyAuthorized nonReentrant {
        _pause();
    }

    function unpause() external onlyAuthorized nonReentrant {
        _unpause();
    }
}
