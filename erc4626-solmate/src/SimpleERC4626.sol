// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "solmate/tokens/ERC4626.sol";

contract SimpleERC4626 is ERC4626 {

    uint256 private _totalAssets;

    constructor(
        ERC20 _asset,
        string memory _name,
        string memory _symbol
    ) ERC4626(_asset, _name, _symbol) {
    }

    function totalAssets() public view virtual override returns (uint256) {
        return _totalAssets;
    }

    function beforeWithdraw(uint256 assets, uint256) internal virtual override {
        _totalAssets = _totalAssets - assets;
    }

    function afterDeposit(uint256 assets, uint256) internal virtual override {
        _totalAssets = _totalAssets + assets;
    }

}