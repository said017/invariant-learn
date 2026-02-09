
# Recon Recap for morpho-blue

## Fuzzer overview
- Fuzzer: ECHIDNA
- Duration: 
- Coverage: 7331
- Failed: 0
- Passed: 23
- Number of tests: 1000378

<details>
  <summary> <h2> Results </h2> </summary>

| Property | Status |
|----------|--------|
| morpho_liquidate((address,address,address,address,uint256),address,uint256,uint256,bytes) | ✅ |
| morpho_flashLoan(address,uint256,bytes) | ✅ |
| morpho_setFee((address,address,address,address,uint256),uint256) | ✅ |
| asset_approve(address,uint128) | ✅ |
| morpho_repay((address,address,address,address,uint256),uint256,uint256,address,bytes) | ✅ |
| switch_asset(uint256) | ✅ |
| morpho_withdraw((address,address,address,address,uint256),uint256,uint256,address,address) | ✅ |
| morpho_setFeeRecipient(address) | ✅ |
| asset_mint(address,uint128) | ✅ |
| switchActor(uint256) | ✅ |
| morpho_setOwner(address) | ✅ |
| morpho_borrow((address,address,address,address,uint256),uint256,uint256,address,address) | ✅ |
| morpho_setAuthorization(address,bool) | ✅ |
| morpho_withdrawCollateral((address,address,address,address,uint256),uint256,address,address) | ✅ |
| morpho_createMarket((address,address,address,address,uint256)) | ✅ |
| add_new_asset(uint8) | ✅ |
| morpho_setAuthorizationWithSig((address,address,bool,uint256,uint256),(uint8,bytes32,bytes32)) | ✅ |
| morpho_enableIrm(address) | ✅ |
| morpho_supplyCollateral((address,address,address,address,uint256),uint256,address,bytes) | ✅ |
| morpho_supply((address,address,address,address,uint256),uint256,uint256,address,bytes) | ✅ |
| morpho_enableLltv(uint256) | ✅ |
| morpho_accrueInterest((address,address,address,address,uint256)) | ✅ |
| AssertionFailed(..) | ✅ |



</details>

