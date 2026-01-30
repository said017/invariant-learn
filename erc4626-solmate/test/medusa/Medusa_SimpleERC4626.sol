// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {SimpleERC4626} from "../../src/SimpleERC4626.sol";
import {MockERC20} from "../mocks/MockERC20.sol";
import {ERC20} from "solmate/tokens/ERC20.sol";

/// @dev Helper that holds underlying tokens and can deposit/withdraw on behalf of Medusa callers.
///      Needed because the vault cannot safeTransferFrom itself without double-counting.
contract MedusaVaultHelper {
    SimpleERC4626 public vault;
    MockERC20 public token;

    constructor(SimpleERC4626 _vault, MockERC20 _token) {
        vault = _vault;
        token = _token;
        token.approve(address(_vault), type(uint256).max);
    }

    function doDeposit(uint256 assets, address receiver) external returns (uint256) {
        token.mint(address(this), assets);
        return vault.deposit(assets, receiver);
    }

    function doMint(uint256 shares, address receiver) external returns (uint256) {
        uint256 assetsNeeded = vault.previewMint(shares);
        token.mint(address(this), assetsNeeded);
        return vault.mint(shares, receiver);
    }

    function doWithdraw(uint256 assets, address receiver, address owner) external returns (uint256) {
        return vault.withdraw(assets, receiver, owner);
    }

    function doRedeem(uint256 shares, address receiver, address owner) external returns (uint256) {
        return vault.redeem(shares, receiver, owner);
    }
}

contract Medusa_SimpleERC4626 is SimpleERC4626 {
    uint256 internal constant MAX_ASSETS = type(uint128).max;

    MockERC20 internal mockAsset;
    MedusaVaultHelper internal helper;

    mapping(address => bool) internal isTracked;
    address[] internal users;

    constructor()
        SimpleERC4626(
            new MockERC20(),
            "Vault Token",
            "vTkn"
        )
    {
        mockAsset = MockERC20(address(asset));
        helper = new MedusaVaultHelper(this, mockAsset);
    }

    // ─── User tracking ───────────────────────────────────────────

    function _trackUser(address user) internal {
        if (!isTracked[user]) {
            isTracked[user] = true;
            users.push(user);
        }
    }

    // Track share recipients on transfer/transferFrom
    function transfer(address to, uint256 amount) public override returns (bool) {
        _trackUser(msg.sender);
        _trackUser(to);
        return super.transfer(to, amount);
    }

    function transferFrom(address from, address to, uint256 amount) public override returns (bool) {
        _trackUser(from);
        _trackUser(to);
        return super.transferFrom(from, to, amount);
    }

    // ─── Handler functions ───────────────────────────────────────

    function handler_deposit(uint256 assets) external {
        assets = (assets % MAX_ASSETS) + 1;
        _trackUser(msg.sender);
        helper.doDeposit(assets, msg.sender);
    }

    function handler_withdraw(uint256 assets) external {
        uint256 maxAssets = maxWithdraw(msg.sender);
        if (maxAssets == 0) return;

        assets = (assets % maxAssets) + 1;
        uint256 sharesNeeded = previewWithdraw(assets);
        allowance[msg.sender][address(helper)] = sharesNeeded;
        helper.doWithdraw(assets, msg.sender, msg.sender);
    }

    function handler_mint(uint256 shares) external {
        shares = (shares % MAX_ASSETS) + 1;

        uint256 assetsNeeded = previewMint(shares);
        if (assetsNeeded == 0) return;

        _trackUser(msg.sender);
        helper.doMint(shares, msg.sender);
    }

    function handler_redeem(uint256 shares) external {
        uint256 maxShares = maxRedeem(msg.sender);
        if (maxShares == 0) return;

        shares = (shares % maxShares) + 1;
        allowance[msg.sender][address(helper)] = shares;
        helper.doRedeem(shares, msg.sender, msg.sender);
    }

    // ─── Property invariants (fuzz_ prefix for Medusa) ───────────

    // 1. Solvency: vault holds at least as many underlying tokens as totalAssets()
    function fuzz_solvency() public view returns (bool) {
        return asset.balanceOf(address(this)) >= totalAssets();
    }

    // 2. Sum of all tracked user balances == totalSupply
    function fuzz_balance_sum_eq_total_supply() public view returns (bool) {
        uint256 sum = 0;
        uint256 len = users.length;
        for (uint256 i = 0; i < len; i++) {
            sum += balanceOf[users[i]];
        }
        return sum == totalSupply;
    }

    // 3. Zero supply implies zero assets
    function fuzz_zero_supply_implies_zero_assets() public view returns (bool) {
        if (totalSupply == 0) {
            return totalAssets() == 0;
        }
        return true;
    }

    // 4. Share price consistency: round-trip should not create value
    //    convertToAssets(convertToShares(x)) <= x
    function fuzz_no_free_value_on_roundtrip() public view returns (bool) {
        uint256 testAmount = 1e18;
        if (totalSupply == 0) return true;
        uint256 shares = convertToShares(testAmount);
        uint256 assetsBack = convertToAssets(shares);
        return assetsBack <= testAmount;
    }
}
