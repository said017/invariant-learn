// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Test} from "forge-std/Test.sol";
import {RewardsManager} from "../src/RewardManager.sol";

contract RewardManagerTest is Test {
    RewardsManager public rewardManager;

    function setUp() public {
        rewardManager = new RewardsManager();
    }

    // function test_Increment() public {
    //     counter.increment();
    //     assertEq(counter.number(), 1);
    // }

    // function testFuzz_SetNumber(uint256 x) public {
    //     counter.setNumber(x);
    //     assertEq(counter.number(), x);
    // }
}
