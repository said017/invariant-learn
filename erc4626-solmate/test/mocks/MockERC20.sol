// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "solmate/tokens/ERC20.sol";

contract MockERC20 is ERC20 {

    constructor() ERC20("Mock Token", "Mock", 18) {
    }

    function mint(address user, uint256 amount) public returns(uint256) {
        _mint(user, amount);
        return amount;
    }

    function burn(address user, uint256 amount) public returns(uint256) {
        _burn(user, amount);
        return amount;
    }

}