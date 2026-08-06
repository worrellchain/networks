#!/usr/bin/env bash
#
# Worrell testnet — setup-genesis.sh
# Builds the worrell-testnet-1 genesis. Identical to mainnet except for the chain_id and
# the reduced times (unbonding, governance, jail) for quick testing.
# It also applies founder vesting, IBC disabled and a 40M block gas limit.
#
# The faucet (george, 500 WORRELL per request, :4500) is NOT part of the genesis:
# it is a separate service started with `worrelld` / `ignite faucet`.
#
# It reuses the mainnet key/multisig creator (setup-multisig.sh (in this same folder)),
# which is generic and network-independent.
#
# Environment variables (with defaults):
#   HOME_DIR          data directory           (default ~/.worrell)
#   KEYRING_BACKEND   os | file | test         (default test)
#   GENESIS_TIME_UNIX genesis epoch            (default: now)
#   WORRELLD          path to the binary       (default worrelld)
#
set -euo pipefail

WORRELLD="${WORRELLD:-worrelld}"
HOME_DIR="${HOME_DIR:-$HOME/.worrell}"
KEYRING_BACKEND="${KEYRING_BACKEND:-test}"
GENESIS_TIME_UNIX="${GENESIS_TIME_UNIX:-$(date +%s)}"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
MULTISIG_SCRIPT="$SCRIPT_DIR/setup-multisig.sh"

CHAIN_ID="worrell-testnet-1"
MONIKER="henry"
DENOM="uworrell"

# --- Times (TESTNET, reduced) ---
UNBONDING="3600s"        # 1 hour
JAIL="300s"              # 5 minutes
DEP_PERIOD="600s"        # 10 minutes
VOTING="300s"            # 5 minutes
EXP_VOTING="120s"        # 2 minutes

# --- Vesting anchor (same offsets as mainnet) ---
VESTING_START=$((GENESIS_TIME_UNIX + 31557600))   # genesis + 1 year
VESTING_END=$((GENESIS_TIME_UNIX + 126230400))    # genesis + 4 years

# --- Amounts (uworrell) ---
HENRY_TOTAL=100000000000000
GEORGE_TOTAL=50000000000000
CHARLIE_TOTAL=50000000000000
TREASURY=300000000000000
AIRDROP=225000000000000
INCENTIVES=175000000000000
RESERVE=100000000000000
SELF_DELEGATION=20000000000000
MIN_SELF_DELEGATION=1000000

KB=(--keyring-backend "$KEYRING_BACKEND" --home "$HOME_DIR")
GENESIS="$HOME_DIR/config/genesis.json"

to_iso() {
  date -u -d "@$1" +%Y-%m-%dT%H:%M:%S.000000000Z 2>/dev/null \
    || date -u -r "$1" +%Y-%m-%dT%H:%M:%S.000000000Z
}

echo "==> [1/6] init ($CHAIN_ID)"
rm -rf "$HOME_DIR"
"$WORRELLD" init "$MONIKER" --chain-id "$CHAIN_ID" --home "$HOME_DIR" >/dev/null 2>&1

echo "==> [2/6] keys and multisig"
HOME_DIR="$HOME_DIR" KEYRING_BACKEND="$KEYRING_BACKEND" WORRELLD="$WORRELLD" \
  bash "$MULTISIG_SCRIPT"

A_HENRY=$("$WORRELLD" keys show henry -a "${KB[@]}")
A_GEORGE=$("$WORRELLD" keys show george -a "${KB[@]}")
A_CHARLIE=$("$WORRELLD" keys show charlie -a "${KB[@]}")
A_TREASURY=$("$WORRELLD" keys show treasury -a "${KB[@]}")
A_AIRDROP=$("$WORRELLD" keys show airdrop -a "${KB[@]}")
A_INCENTIVES=$("$WORRELLD" keys show incentives -a "${KB[@]}")
A_RESERVE=$("$WORRELLD" keys show reserve -a "${KB[@]}")

echo "==> [3/6] genesis accounts (founders with continuous vesting, community multisig)"
"$WORRELLD" genesis add-genesis-account "$A_HENRY" "${HENRY_TOTAL}${DENOM}" \
  --vesting-amount "${HENRY_TOTAL}${DENOM}" \
  --vesting-start-time "$VESTING_START" --vesting-end-time "$VESTING_END" "${KB[@]}"
# george: NO vesting on testnet so it can operate the faucet (§16).
# henry and charlie keep their vesting; in mainnet (no faucet) george is vesting too.
"$WORRELLD" genesis add-genesis-account "$A_GEORGE" "${GEORGE_TOTAL}${DENOM}" "${KB[@]}"
"$WORRELLD" genesis add-genesis-account "$A_CHARLIE" "${CHARLIE_TOTAL}${DENOM}" \
  --vesting-amount "${CHARLIE_TOTAL}${DENOM}" \
  --vesting-start-time "$VESTING_START" --vesting-end-time "$VESTING_END" "${KB[@]}"
"$WORRELLD" genesis add-genesis-account "$A_TREASURY"   "${TREASURY}${DENOM}"   "${KB[@]}"
"$WORRELLD" genesis add-genesis-account "$A_AIRDROP"    "${AIRDROP}${DENOM}"    "${KB[@]}"
"$WORRELLD" genesis add-genesis-account "$A_INCENTIVES" "${INCENTIVES}${DENOM}" "${KB[@]}"
"$WORRELLD" genesis add-genesis-account "$A_RESERVE"    "${RESERVE}${DENOM}"    "${KB[@]}"

GTS="$(to_iso "$GENESIS_TIME_UNIX")"
tmp=$(mktemp); jq --arg ts "$GTS" '.genesis_time = $ts' "$GENESIS" > "$tmp" && mv "$tmp" "$GENESIS"

echo "==> [4/6] henry gentx (self-delegation ${SELF_DELEGATION}${DENOM} = 20M)"
"$WORRELLD" genesis gentx henry "${SELF_DELEGATION}${DENOM}" \
  --chain-id "$CHAIN_ID" \
  --commission-rate "0.05" \
  --commission-max-rate "0.25" \
  --commission-max-change-rate "0.01" \
  --min-self-delegation "$MIN_SELF_DELEGATION" "${KB[@]}"
"$WORRELLD" genesis collect-gentxs --home "$HOME_DIR" >/dev/null 2>&1

echo "==> [5/6] module parameters, IBC disabled and block gas limit"
tmp=$(mktemp)
jq \
  --arg unbonding "$UNBONDING" --arg jail "$JAIL" \
  --arg dep "$DEP_PERIOD" --arg voting "$VOTING" --arg exp "$EXP_VOTING" \
  '
  .consensus.params.block.max_gas = "40000000"
  | .app_state.staking.params.bond_denom = "uworrell"
  | .app_state.staking.params.unbonding_time = $unbonding
  | .app_state.staking.params.max_validators = 100
  | .app_state.staking.params.max_entries = 7
  | .app_state.staking.params.historical_entries = 10000
  | .app_state.staking.params.min_commission_rate = "0.050000000000000000"
  | .app_state.mint.minter.inflation = "0.130000000000000000"
  | .app_state.mint.params.mint_denom = "uworrell"
  | .app_state.mint.params.inflation_rate_change = "0.130000000000000000"
  | .app_state.mint.params.inflation_max = "0.130000000000000000"
  | .app_state.mint.params.inflation_min = "0.070000000000000000"
  | .app_state.mint.params.goal_bonded = "0.670000000000000000"
  | .app_state.mint.params.blocks_per_year = "6311520"
  | .app_state.slashing.params.signed_blocks_window = "10000"
  | .app_state.slashing.params.min_signed_per_window = "0.050000000000000000"
  | .app_state.slashing.params.downtime_jail_duration = $jail
  | .app_state.slashing.params.slash_fraction_double_sign = "0.050000000000000000"
  | .app_state.slashing.params.slash_fraction_downtime = "0.000100000000000000"
  | .app_state.distribution.params.community_tax = "0.100000000000000000"
  | .app_state.gov.params.min_deposit = [{"denom":"uworrell","amount":"1500000000"}]
  | .app_state.gov.params.max_deposit_period = $dep
  | .app_state.gov.params.voting_period = $voting
  | .app_state.gov.params.quorum = "0.334000000000000000"
  | .app_state.gov.params.threshold = "0.500000000000000000"
  | .app_state.gov.params.veto_threshold = "0.334000000000000000"
  | .app_state.gov.params.burn_vote_quorum = true
  | .app_state.gov.params.burn_proposal_deposit_prevote = false
  | .app_state.gov.params.burn_vote_veto = true
  | .app_state.gov.params.expedited_min_deposit = [{"denom":"uworrell","amount":"7500000000"}]
  | .app_state.gov.params.expedited_voting_period = $exp
  | .app_state.gov.params.expedited_threshold = "0.667000000000000000"
  | .app_state.transfer.params.send_enabled = false
  | .app_state.transfer.params.receive_enabled = false
  ' "$GENESIS" > "$tmp" && mv "$tmp" "$GENESIS"

echo "==> [6/6] validation"
"$WORRELLD" genesis validate-genesis --home "$HOME_DIR"

cat <<EOF

============ GENESIS worrell-testnet-1 READY ============
 genesis_time : $GTS
 Testnet times: unbonding $UNBONDING | voting $VOTING | jail $JAIL
 Total supply : 1,000,000,000 WORRELL (1000000000000000 uworrell)
 Faucet       : george, 500 WORRELL/request, :4500 (start separately)
 Genesis at   : $GENESIS
========================================================
EOF
