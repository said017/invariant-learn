// SPDX-License-Identifier: GPL-2.0
pragma solidity ^0.8.0;

import {FoundryAsserts} from "@chimera/FoundryAsserts.sol";

import "forge-std/console2.sol";

import {Test} from "forge-std/Test.sol";
import {TargetFunctions} from "./TargetFunctions.sol";


// forge test --match-contract CryticToFoundry -vv
contract CryticToFoundry is Test, TargetFunctions, FoundryAsserts {
    function setUp() public {
        setup();

        targetContract(address(this));
    }

    // forge test --match-test test_crytic -vvv
    function test_crytic() public {
        morpho_supply(1e18, 0, _getActor(), hex"");// testing supplying assets to a market as the default actor (address(this))
        morpho_supplyCollateral(1e18, _getActor(), hex"");
    }

    // forge test --match-test test_canary_hasRepaid_zxv9 -vvv
    function test_canary_hasRepaid_zxv9() public {
    
        morpho_supplyCollateral_clamped(620868177084);
    
        morpho_supply_clamped(1);
    
        oracle_setPrice(3221466766501911336923921);
    
        morpho_borrow(1,0,0x7FA9385bE102ac3EAc297483Dd6233D62b3e1496,0x00000000000000000000000000000000DeaDBeef);
    
        morpho_repay_clamped(1);
    
        // canary_hasRepaid();
    
    }
}