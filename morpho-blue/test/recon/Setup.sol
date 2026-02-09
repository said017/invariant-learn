// SPDX-License-Identifier: GPL-2.0
pragma solidity ^0.8.0;

// Chimera deps
import {BaseSetup} from "@chimera/BaseSetup.sol";
import {vm} from "@chimera/Hevm.sol";

// Managers
import {ActorManager} from "@recon/ActorManager.sol";
import {AssetManager} from "@recon/AssetManager.sol";

// Helpers
import {Utils} from "@recon/Utils.sol";

// Your deps
import "src/Morpho.sol";

// Add import for MarketParams
import {Morpho, MarketParams} from "src/Morpho.sol";

import {IrmMock} from "src/mocks/IrmMock.sol";
import {OracleMock} from "src/mocks/OracleMock.sol";
import {MockERC20} from "@recon/MockERC20.sol";

abstract contract Setup is BaseSetup, ActorManager, AssetManager, Utils {
    Morpho morpho;
    
    // Mocks
    IrmMock irm;
    OracleMock oracle;

    MarketParams marketParams;
    bool hasRepaid;
    bool hasLiquidated;
    
    /// === Setup === ///
    /// This contains all calls to be performed in the tester constructor, both for Echidna and Foundry
    function setup() internal virtual override {
        morpho = new Morpho(_getActor());

        // Deploy Mocks
        irm = new IrmMock();
        oracle = new OracleMock();

        // Deploy assets
        _newAsset(18); // asset
        _newAsset(18); // liability

        // Create the market 
        morpho.enableIrm(address(irm));
        morpho.enableLltv(8e17); 

        _setupAssetsAndApprovals();

        address[] memory assets = _getAssets();
        marketParams = MarketParams({
            loanToken: assets[1],
            collateralToken: assets[0],
            oracle: address(oracle),
            irm: address(irm),
            lltv: 8e17
        });
        morpho.createMarket(marketParams);
    }

    function _setupAssetsAndApprovals() internal {
        address[] memory actors = _getActors();
        uint256 amount = type(uint88).max;
        
        // Process each asset separately to reduce stack depth
        for (uint256 assetIndex = 0; assetIndex < _getAssets().length; assetIndex++) {
            address asset = _getAssets()[assetIndex];
            
            // Mint to actors
            for (uint256 i = 0; i < actors.length; i++) {
                vm.prank(actors[i]);
                MockERC20(asset).mint(actors[i], amount);
            }
            
            // Approve to morpho
            for (uint256 i = 0; i < actors.length; i++) {
                vm.prank(actors[i]);
                MockERC20(asset).approve(address(morpho), type(uint88).max);
            }
        }
    }

    /// === MODIFIERS === ///
    /// Prank admin and actor
    
    modifier asAdmin {
        vm.prank(address(this));
        _;
    }

    modifier asActor {
        vm.prank(address(_getActor()));
        _;
    }
}
