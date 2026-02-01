# Invariant Bootcamp Notes

Notes and exercises from the Invariant Testing Bootcamp.

## Week 1 — Scaffold a ERC4626 vault "by hand" and reach 90% coverage (erc4626-solmate)

### Vault

`src/SimpleERC4626.sol` — A minimal ERC4626 vault built on top of solmate's `ERC4626` base. Tracks `_totalAssets` internally via `afterDeposit` and `beforeWithdraw` hooks.

### Fuzz Test Suites

| File | Fuzzer | Contract |
|------|--------|----------|
| `test/echidna/Echidna_SimpleERC4626.sol` | Echidna | `Echidna_SimpleERC4626` |
| `test/medusa/Medusa_SimpleERC4626.sol` | Medusa | `Medusa_SimpleERC4626` |

Both suites use an identical setup:

- **`VaultHelper`** — A helper contract that holds underlying tokens, approves the vault, and calls `deposit`/`mint`/`withdraw`/`redeem`. Needed because the test contract inherits the vault, so it can't `safeTransferFrom` itself without double-counting.
- **Handler functions** (`handler_deposit`, `handler_withdraw`, `handler_mint`, `handler_redeem`) — Wrappers that mint underlying tokens, set up approvals, and call vault operations so the fuzzer can explore meaningful state.

### Properties / Invariants Tested

| # | Property | Description |
|---|----------|-------------|
| 1 | **Solvency** | `asset.balanceOf(vault) >= totalAssets()` — The vault always holds at least as many underlying tokens as the totalAssets. |
| 2 | **Balance sum = total supply** | Sum of all tracked user share balances equals `totalSupply`. |
| 3 | **Zero supply implies zero assets** | If `totalSupply == 0` then `totalAssets() == 0` — no stuck assets when the vault is empty. |
| 4 | **No free value on round-trip** | `convertToAssets(convertToShares(x)) <= x` — Converting assets to shares and back never creates value (rounding favors the vault). |

### How to Run

#### Build

```bash
forge build
```

#### Echidna

```bash
echidna ./test/echidna/Echidna_SimpleERC4626.sol \
  --contract Echidna_SimpleERC4626 \
  --config test/echidna/echidna.yaml
```

#### Medusa

```bash
medusa fuzz
```

Medusa reads `medusa.json` from the project root automatically.

---

### RewardManager

`reward-manager-manual/src/RewardManager.sol` 

### Fuzz Test Suites

| File | Fuzzer | Contract |
|------|--------|----------|
| `test/echidna/Echidna_RewardManager.sol` | Echidna | `Echidna_RewardManager` |
| `test/medusa/Medusa_RewardManager.sol` | Medusa | `Medusa_RewardManager` |

The test contract acts as the "vault" (`msg.sender` for `notifyTransfer`). It uses a fixed set of 3 user addresses and clamps fuzzed inputs to valid ranges.

**Handler functions:**
- `handler_deposit` / `handler_withdraw` / `handler_transfer` — simulate vault balance changes via `notifyTransfer`
- `handler_addReward` — mints reward tokens and adds them for the current epoch
- `handler_accrueVault` / `handler_accrueUser` / `handler_accrueAll` — trigger point accrual
- `handler_claimRewardReference` / `handler_claimReward` — claim rewards on past epochs

### Properties / Invariants Tested

| # | Property | Description |
|---|----------|-------------|
| 1 | **Rewards match added** | On-chain `rewards[epoch][vault][token]` equals the tracked total added via `addReward`. |
| 2 | **Shares sum <= total supply** | Sum of all tracked user shares <= `totalSupply` for the current epoch. Accounts for lazy evaluation. |
| 3 | **Points sum <= total points** | Sum of all tracked user points <= `totalPoints` for the current epoch. |
| 4 | **Epoch always >= 1** | `currentEpoch()` is always at least 1. |

### How to Run

```bash
cd reward-manager-manual
```

#### Build

```bash
forge build
```

#### Echidna

```bash
echidna ./test/echidna/Echidna_RewardManager.sol \
  --contract Echidna_RewardManager \
  --config test/echidna/echidna.yaml
```

#### Medusa

```bash
medusa fuzz
```

Medusa reads `medusa.json` from the project root automatically.
