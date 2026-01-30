// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Test} from "forge-std/Test.sol";
import {SimpleERC4626} from "../src/SimpleERC4626.sol";
import {MockERC20} from "./mocks/MockERC20.sol";


contract SimpleERC4626Test is Test {
   SimpleERC4626 public simpleERC4626;
   MockERC20 public mockERC20;
   address userA = address(0xABC);
   address userB = address(0xBCD);

    function setUp() public {
        mockERC20 = new MockERC20();
        simpleERC4626 = new SimpleERC4626(mockERC20, "Simple Vault", "sVault");
        // mockERC20.mint(userA, 100e18);
        // mockERC20.mint(userB, 100e18);
    }

    // deposit x asset should increase totalAssets by x
    function testFuzz_deposit(uint256 x) public {
        x = bound(x, 1, type(uint128).max);
        vm.startPrank(userA);
        mockERC20.mint(userA, x);
        uint256 totalAssetsBefore = simpleERC4626.totalAssets();
        mockERC20.approve(address(simpleERC4626), x);
        simpleERC4626.deposit(x, userA);
        vm.stopPrank();
        uint256 totalAssetsAfter = simpleERC4626.totalAssets();
        assertEq(totalAssetsBefore + x, totalAssetsAfter);
    }

    // withdraw x asset should decrease totalAssets by x
    function testFuzz_withdraw(uint256 x) public {
        x = bound(x, 1,  type(uint128).max);
        vm.startPrank(userA);
        mockERC20.mint(userA, x);
        mockERC20.approve(address(simpleERC4626), x);
        simpleERC4626.deposit(x, userA);
        uint256 totalAssetsBefore = simpleERC4626.totalAssets();
        simpleERC4626.withdraw(x, userA, userA);
        vm.stopPrank();
        uint256 totalAssetsAfter = simpleERC4626.totalAssets();
        assertEq(totalAssetsBefore - x, totalAssetsAfter);
    }

    // mint x shares should increase totalSupply by x
    function testFuzz_mint(uint256 x) public {
        x = bound(x, 1, type(uint128).max);
        vm.startPrank(userA);
        uint256 assets = simpleERC4626.previewMint(x);
        mockERC20.mint(userA, assets);
        uint256 totalSharesBefore = simpleERC4626.totalSupply();
        mockERC20.approve(address(simpleERC4626), x);
        simpleERC4626.mint(x, userA);
        vm.stopPrank();
        uint256 totalSharesAfter = simpleERC4626.totalSupply();
        assertEq(totalSharesBefore + x, totalSharesAfter);
    }

    // redeem x shares should increase totalSupply by x
    function testFuzz_redeem(uint256 x) public {
        x = bound(x, 1, type(uint128).max);
        vm.startPrank(userA);
        uint256 assets = simpleERC4626.previewMint(x);
        mockERC20.mint(userA, assets);
        mockERC20.approve(address(simpleERC4626), x);
        simpleERC4626.mint(x, userA);
        uint256 totalSharesBefore = simpleERC4626.totalSupply();
        simpleERC4626.redeem(x, userA, userA);
        vm.stopPrank();
        uint256 totalSharesAfter = simpleERC4626.totalSupply();
        assertEq(totalSharesBefore - x, totalSharesAfter);
    }
}
