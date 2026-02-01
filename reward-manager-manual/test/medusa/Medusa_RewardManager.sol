// SPDX-License-Identifier: GPL-2.0
pragma solidity 0.8.24;

import {RewardsManager} from "../../src/RewardManager.sol";
import {MockERC20} from "../mocks/MockERC20.sol";
import {IERC20} from "@openzeppelin/token/ERC20/IERC20.sol";

contract Medusa_RewardManager {
    uint256 internal constant MAX_AMOUNT = type(uint112).max;

    RewardsManager public manager;
    MockERC20 public rewardToken;

    // Fixed set of user addresses
    address internal constant USER_A = address(0x10000);
    address internal constant USER_B = address(0x20000);
    address internal constant USER_C = address(0x30000);

    // total rewards added per epoch for this vault
    mapping(uint256 => uint256) internal rewardsAdded;

    // total rewards ever deposited into the manager (across all epochs)
    uint256 internal totalRewardsDeposited;

    constructor() {
        manager = new RewardsManager();
        rewardToken = new MockERC20("Reward", "Tkn");
    }

    function _clampUser(uint256 seed) internal pure returns (address) {
        uint256 idx = seed % 3;
        if (idx == 0) return USER_A;
        if (idx == 1) return USER_B;
        return USER_C;
    }

    // ─── Handler functions ───────────────────────────────────────

    function handler_deposit(uint256 userSeed, uint256 amount) external {
        amount = (amount % MAX_AMOUNT) + 1;
        address user = _clampUser(userSeed);
        manager.notifyTransfer(address(0), user, amount);
    }

    function handler_withdraw(uint256 userSeed, uint256 amount) external {
        address user = _clampUser(userSeed);
        uint256 epoch = manager.currentEpoch();
        uint256 userShares = manager.shares(epoch, address(this), user);
        if (userShares == 0) return;

        amount = (amount % userShares) + 1;

        manager.notifyTransfer(user, address(0), amount);
    }

    function handler_transfer(uint256 fromSeed, uint256 toSeed, uint256 amount) external {
        address from = _clampUser(fromSeed);
        address to = _clampUser(toSeed);
        if (from == to) return;

        uint256 epoch = manager.currentEpoch();
        uint256 fromShares = manager.shares(epoch, address(this), from);
        if (fromShares == 0) return;

        amount = (amount % fromShares) + 1;
        manager.notifyTransfer(from, to, amount);
    }

    function handler_addReward(uint256 amount) external {
        amount = (amount % MAX_AMOUNT) + 1;
        uint256 epoch = manager.currentEpoch();

        rewardToken.mint(address(this), amount);
        rewardToken.approve(address(manager), amount);

        manager.addReward(epoch, address(this), address(rewardToken), amount);
        rewardsAdded[epoch] += amount;
        totalRewardsDeposited += amount;
    }

    function handler_accrueVault(uint256 epochOffset) external {
        uint256 epoch = manager.currentEpoch();
        uint256 targetEpoch = (epochOffset % epoch) + 1;
        manager.accrueVault(targetEpoch, address(this));
    }

    function handler_accrueUser(uint256 userSeed, uint256 epochOffset) external {
        address user = _clampUser(userSeed);
        uint256 epoch = manager.currentEpoch();
        uint256 targetEpoch = (epochOffset % epoch) + 1;
        manager.accrueUser(targetEpoch, address(this), user);
    }

    /// @dev Claim reward for a user on a past epoch using the full reference version
    ///      (accrues vault + user + address(this), then claims)
    function handler_claimRewardReference(uint256 userSeed, uint256 epochOffset) external {
        uint256 epoch = manager.currentEpoch();
        if (epoch <= 1) return; // need at least one ended epoch

        uint256 targetEpoch = (epochOffset % (epoch - 1)) + 1; // clamp to [1, epoch-1]
        address user = _clampUser(userSeed);

        try manager.claimRewardReferenceEmitting(targetEpoch, address(this), address(rewardToken), user) {
        } catch {
            // Revert is fine (e.g. zero points, already claimed)
        }
    }

    /// @dev Claim reward using the non-accruing version (for non-emitting vaults)
    function handler_claimReward(uint256 userSeed, uint256 epochOffset) external {
        uint256 epoch = manager.currentEpoch();
        if (epoch <= 1) return;

        uint256 targetEpoch = (epochOffset % (epoch - 1)) + 1;
        address user = _clampUser(userSeed);

        try manager.claimReward(targetEpoch, address(this), address(rewardToken), user) {
        } catch {
            // Revert is fine
        }
    }

    /// @dev Force full accrual of vault + all users for the current epoch.
    function handler_accrueAll() external {
        uint256 epoch = manager.currentEpoch();
        manager.accrueVault(epoch, address(this));
        manager.accrueUser(epoch, address(this), USER_A);
        manager.accrueUser(epoch, address(this), USER_B);
        manager.accrueUser(epoch, address(this), USER_C);
    }

    // ─── Property invariants (fuzz_ prefix for Medusa) ───────────

    /// @dev Rewards stored on-chain match what was added (no inflation/deflation)
    function fuzz_rewards_match_added() public view returns (bool) {
        uint256 epoch = manager.currentEpoch();
        uint256 onChain = manager.rewards(epoch, address(this), address(rewardToken));
        return onChain == rewardsAdded[epoch];
    }

    /// @dev Sum of user shares <= totalSupply for the current epoch
    function fuzz_shares_sum_lte_supply() public view returns (bool) {
        uint256 epoch = manager.currentEpoch();
        uint256 supply = manager.totalSupply(epoch, address(this));
        uint256 sum = manager.shares(epoch, address(this), USER_A)
                    + manager.shares(epoch, address(this), USER_B)
                    + manager.shares(epoch, address(this), USER_C);
        return sum <= supply;
    }

    /// @dev Sum of user points <= totalPoints for the current epoch
    function fuzz_points_sum_lte_total() public view returns (bool) {
        uint256 epoch = manager.currentEpoch();
        uint256 total = manager.totalPoints(epoch, address(this));
        uint256 sum = manager.points(epoch, address(this), USER_A)
                    + manager.points(epoch, address(this), USER_B)
                    + manager.points(epoch, address(this), USER_C);
        return sum <= total;
    }

    /// @dev currentEpoch should always be >= 1 (first epoch is 1)
    function fuzz_epoch_always_gte_1() public view returns (bool) {
        return manager.currentEpoch() >= 1;
    }
}
