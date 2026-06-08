#!/usr/bin/env bash
set -euo pipefail

RPC_URL="${RPC_URL:-http://127.0.0.1:8545}"
PRIVATE_KEY="${PRIVATE_KEY:-0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80}"
ANVIL_LOG="${ANVIL_LOG:-/tmp/yieldstream-demo-anvil.log}"
STARTED_ANVIL=0

require_cmd() {
  if ! command -v "$1" >/dev/null 2>&1; then
    echo "Missing required command: $1" >&2
    exit 1
  fi
}

ensure_anvil() {
  if cast chain-id --rpc-url "$RPC_URL" >/dev/null 2>&1; then
    return
  fi

  echo "No JSON-RPC node detected at $RPC_URL; starting local Anvil..."
  anvil --host 127.0.0.1 --port 8545 >"$ANVIL_LOG" 2>&1 &
  STARTED_ANVIL=1
  ANVIL_PID=$!
  trap 'if [[ "$STARTED_ANVIL" == "1" ]]; then kill "$ANVIL_PID" >/dev/null 2>&1 || true; fi' EXIT

  for _ in {1..30}; do
    if cast chain-id --rpc-url "$RPC_URL" >/dev/null 2>&1; then
      return
    fi
    sleep 0.2
  done

  echo "Anvil did not become ready. Log: $ANVIL_LOG" >&2
  exit 1
}

print_hashes() {
  local title="$1"
  local file="$2"

  echo
  echo "$title"
  jq -r '
    .transactions[]
    | select(.hash != null)
    | def fn: ((.function // "unknown") | split("(")[0]);
      if .transactionType == "CREATE" then
        "  " + (.transactionType // "TX") + " " + (.contractName // "contract") + " -> " + (.contractAddress // "-") + "\n    txid: " + .hash
      elif fn == "demoSettleEpoch" then
        "  CALL DemoYieldStreamHookHarness.demoSettleEpoch\n    txid: " + .hash
      elif fn == "redeemAllFYT" then
        "  CALL BobActor.redeemAllFYT\n    txid: " + .hash
      elif fn == "redeemAllPT" then
        "  CALL AliceActor.redeemAllPT\n    txid: " + .hash
      else
        "  CALL " + (.contractName // "contract") + "." + fn + "\n    txid: " + .hash
      end
  ' "$file"
}

require_cmd forge
require_cmd cast
require_cmd anvil
require_cmd jq
ensure_anvil

CHAIN_ID="$(cast chain-id --rpc-url "$RPC_URL")"

echo "YieldStream judge demo"
echo "RPC:      $RPC_URL"
echo "Chain ID: $CHAIN_ID"
echo

RUST_LOG=error forge script script/DemoYieldStreamSetup.s.sol:DemoYieldStreamSetup \
  --rpc-url "$RPC_URL" \
  --private-key "$PRIVATE_KEY" \
  --broadcast \
  -vvv

echo
echo "Settling through the demo harness so judges do not wait for 50,400 blocks..."

RUST_LOG=error forge script script/DemoYieldStreamSettleRedeem.s.sol:DemoYieldStreamSettleRedeem \
  --rpc-url "$RPC_URL" \
  --private-key "$PRIVATE_KEY" \
  --broadcast \
  -vvv

SETUP_JSON="broadcast/DemoYieldStreamSetup.s.sol/$CHAIN_ID/run-latest.json"
SETTLE_JSON="broadcast/DemoYieldStreamSettleRedeem.s.sol/$CHAIN_ID/run-latest.json"

print_hashes "Setup transaction ids" "$SETUP_JSON"
print_hashes "Settlement and redemption transaction ids" "$SETTLE_JSON"

echo
echo "Demo state: broadcast/yieldstream-demo-addresses.json"
