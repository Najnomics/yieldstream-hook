#!/usr/bin/env bash
set -euo pipefail

if [[ -f .env ]]; then
  set -a
  # shellcheck disable=SC1091
  source .env
  set +a
fi

NETWORK="${YIELDSTREAM_E2E_NETWORK:-base}"
REACTIVE_WAIT_SECONDS="${REACTIVE_WAIT_SECONDS:-180}"
REACTIVE_POLL_SECONDS="${REACTIVE_POLL_SECONDS:-6}"
REQUIRE_REACTIVE_EVENT="${REQUIRE_REACTIVE_EVENT:-0}"
LASNA_RPC_URL="${LASNA_RPC_URL:-${REACTIVE_RPC:-https://lasna-rpc.rnk.dev/}}"
CALLBACK_WAIT_SECONDS="${CALLBACK_WAIT_SECONDS:-240}"
CALLBACK_POLL_SECONDS="${CALLBACK_POLL_SECONDS:-6}"
YIELDSTREAM_SETTLEMENT_WAIT_SECONDS="${YIELDSTREAM_SETTLEMENT_WAIT_SECONDS:-180}"
YIELDSTREAM_SETTLEMENT_POLL_SECONDS="${YIELDSTREAM_SETTLEMENT_POLL_SECONDS:-4}"
YIELDSTREAM_TRIGGER_SETTLEMENT_SWAP="${YIELDSTREAM_TRIGGER_SETTLEMENT_SWAP:-1}"
YIELDSTREAM_RUN_SWAPS="${YIELDSTREAM_RUN_SWAPS:-0}"
E2E_DOC="${E2E_DOC:-docs/e2e.md}"
RVM_ID="${RVM_ID:-}"
SUBSCRIPTION_READBACK="false"
SETTLEMENT_TX=""

require_cmd() {
  if ! command -v "$1" >/dev/null 2>&1; then
    echo "Missing required command: $1" >&2
    exit 1
  fi
}

hex_quantity() {
  printf "0x%x" "$1"
}

lower() {
  printf "%s" "$1" | tr '[:upper:]' '[:lower:]'
}

select_network() {
  case "$NETWORK" in
    base|base-sepolia|base_sepolia)
      NETWORK="base"
      DESTINATION_NAME="base-sepolia"
      DESTINATION_RPC_URL="${BASE_SEPOLIA_RPC_URL:?BASE_SEPOLIA_RPC_URL is required}"
      DESTINATION_CHAIN_ID="84532"
      POOL_MANAGER="${BASE_SEPOLIA_POOL_MANAGER:?BASE_SEPOLIA_POOL_MANAGER is required}"
      RSC_ADDRESS="${BASE_SEPOLIA_YIELDSTREAM_RSC_DEMO:-${BASE_SEPOLIA_YIELDSTREAM_RSC_LATEST:-0x180896366174318f5BD64d8320576A488400115a}}"
      RSC_DEPLOY_TX="${BASE_SEPOLIA_YIELDSTREAM_RSC_DEMO_DEPLOY_TX:-${BASE_SEPOLIA_YIELDSTREAM_RSC_DEPLOY_TX:-0xcc1eb12db055da489d33354011f8a15099107606e99684b06e4a23c37bcfe9d1}}"
      RSC_SUBSCRIPTION_TX="${BASE_SEPOLIA_YIELDSTREAM_RSC_DEMO_SUBSCRIPTION_TX:-${BASE_SEPOLIA_YIELDSTREAM_RSC_SUBSCRIPTION_TX:-$RSC_DEPLOY_TX}}"
      HOOK_ADDRESS="${BASE_SEPOLIA_YIELDSTREAM_HOOK_DEMO:-${BASE_SEPOLIA_YIELDSTREAM_HOOK:?BASE_SEPOLIA_YIELDSTREAM_HOOK is required}}"
      SWAP_ROUTER="${BASE_SEPOLIA_POOL_SWAP_TEST:?BASE_SEPOLIA_POOL_SWAP_TEST is required}"
      DEMO_TOKEN0="${BASE_SEPOLIA_YIELDSTREAM_DEMO_TOKEN0:?BASE_SEPOLIA_YIELDSTREAM_DEMO_TOKEN0 is required}"
      DEMO_TOKEN1="${BASE_SEPOLIA_YIELDSTREAM_DEMO_TOKEN1:?BASE_SEPOLIA_YIELDSTREAM_DEMO_TOKEN1 is required}"
      ;;
    unichain|unichain-sepolia|unichain_sepolia)
      NETWORK="unichain"
      DESTINATION_NAME="unichain-sepolia"
      DESTINATION_RPC_URL="${UNICHAIN_SEPOLIA_RPC_URL:?UNICHAIN_SEPOLIA_RPC_URL is required}"
      DESTINATION_CHAIN_ID="1301"
      POOL_MANAGER="${UNICHAIN_SEPOLIA_POOL_MANAGER:?UNICHAIN_SEPOLIA_POOL_MANAGER is required}"
      RSC_ADDRESS="${UNICHAIN_SEPOLIA_YIELDSTREAM_RSC_DEMO:-${UNICHAIN_SEPOLIA_YIELDSTREAM_RSC_LATEST:-0x55b29D0ba5B35C3fDcD81bD6f40eACECc15C4035}}"
      RSC_DEPLOY_TX="${UNICHAIN_SEPOLIA_YIELDSTREAM_RSC_DEMO_DEPLOY_TX:-${UNICHAIN_SEPOLIA_YIELDSTREAM_RSC_DEPLOY_TX:-0x9b9d1d43eb8ce9e1c77f2d0b4dec577f826d0a7e49eb65d54e2a3357021c7131}}"
      RSC_SUBSCRIPTION_TX="${UNICHAIN_SEPOLIA_YIELDSTREAM_RSC_DEMO_SUBSCRIPTION_TX:-${UNICHAIN_SEPOLIA_YIELDSTREAM_RSC_SUBSCRIPTION_TX:-$RSC_DEPLOY_TX}}"
      HOOK_ADDRESS="${UNICHAIN_SEPOLIA_YIELDSTREAM_HOOK_DEMO:-${UNICHAIN_SEPOLIA_YIELDSTREAM_HOOK:?UNICHAIN_SEPOLIA_YIELDSTREAM_HOOK is required}}"
      SWAP_ROUTER="${UNICHAIN_SEPOLIA_POOL_SWAP_TEST:?UNICHAIN_SEPOLIA_POOL_SWAP_TEST is required}"
      DEMO_TOKEN0="${UNICHAIN_SEPOLIA_YIELDSTREAM_DEMO_TOKEN0:?UNICHAIN_SEPOLIA_YIELDSTREAM_DEMO_TOKEN0 is required}"
      DEMO_TOKEN1="${UNICHAIN_SEPOLIA_YIELDSTREAM_DEMO_TOKEN1:?UNICHAIN_SEPOLIA_YIELDSTREAM_DEMO_TOKEN1 is required}"
      ;;
    *)
      echo "Unsupported YIELDSTREAM_E2E_NETWORK='$NETWORK'. Use base or unichain." >&2
      exit 1
      ;;
  esac
}

print_hashes() {
  local title="$1"
  local file="$2"

  echo
  echo "$title"
  jq -r '
    .transactions[]
    | select(.hash != null)
    | def fn: ((.function // "constructor") | split("(")[0]);
      if .transactionType == "CREATE" or .transactionType == "CREATE2" then
        "  " + (.transactionType // "TX") + " " + (.contractName // "contract") + " -> " + (.contractAddress // "-") + "\n    txid: " + .hash
      else
        "  CALL " + (.contractName // "contract") + "." + fn + "\n    txid: " + .hash
      end
  ' "$file"
}

destination_tx_url() {
  local tx="$1"
  case "$DESTINATION_NAME" in
    base-sepolia) echo "https://base-sepolia.blockscout.com/tx/$tx" ;;
    unichain-sepolia) echo "https://unichain-sepolia.blockscout.com/tx/$tx" ;;
    *) echo "$tx" ;;
  esac
}

lasna_tx_url() {
  local tx="$1"
  echo "https://lasna.reactscan.net/tx/$tx"
}

tx_hash_from_json() {
  jq -r '.transactionHash // .hash // empty'
}

init_destination_sender() {
  DEMO_SENDER="$(cast wallet address --private-key "$PRIVATE_KEY")"
  NEXT_DESTINATION_NONCE="$(cast nonce "$DEMO_SENDER" --block pending --rpc-url "$DESTINATION_RPC_URL")"
  echo "Destination sender: $DEMO_SENDER"
  echo "Starting pending nonce: $NEXT_DESTINATION_NONCE"
}

send_destination_tx() {
  local json_output
  local output
  local receipt_status
  local status
  local tx

  NEXT_DESTINATION_NONCE="$(cast nonce "$DEMO_SENDER" --block pending --rpc-url "$DESTINATION_RPC_URL")"
  set +e
  output="$(cast send "$@" --rpc-url "$DESTINATION_RPC_URL" --private-key "$PRIVATE_KEY" --nonce "$NEXT_DESTINATION_NONCE" --json 2>&1)"
  status=$?
  set -e

  if [[ "$status" != "0" && "$output" == *"nonce too low"* ]]; then
    NEXT_DESTINATION_NONCE="$(cast nonce "$DEMO_SENDER" --block pending --rpc-url "$DESTINATION_RPC_URL")"
    echo "Nonce was stale; refreshed pending nonce to $NEXT_DESTINATION_NONCE and retrying once." >&2
    set +e
    output="$(cast send "$@" --rpc-url "$DESTINATION_RPC_URL" --private-key "$PRIVATE_KEY" --nonce "$NEXT_DESTINATION_NONCE" --json 2>&1)"
    status=$?
    set -e
  fi

  if [[ "$status" != "0" ]]; then
    echo "$output" >&2
    return "$status"
  fi

  json_output="$(printf "%s\n" "$output" | sed -n '/^{/,$p')"
  if [[ -z "$json_output" ]]; then
    echo "$output" >&2
    echo "cast send did not return JSON output." >&2
    return 1
  fi

  tx="$(tx_hash_from_json <<<"$json_output")"
  receipt_status="$(jq -r '.status // empty' <<<"$json_output" 2>/dev/null || true)"
  if [[ -z "$receipt_status" || "$receipt_status" == "null" ]]; then
    receipt_status="$(cast receipt "$tx" --rpc-url "$DESTINATION_RPC_URL" --json | jq -r '.status // empty')"
  fi
  if [[ "$receipt_status" == "0x0" || "$receipt_status" == "0" ]]; then
    echo "Transaction reverted: $tx" >&2
    echo "URL: $(destination_tx_url "$tx")" >&2
    return 1
  fi

  NEXT_DESTINATION_NONCE=$((NEXT_DESTINATION_NONCE + 1))
  printf "%s" "$json_output"
}

ensure_e2e_doc() {
  mkdir -p "$(dirname "$E2E_DOC")"
  if [[ ! -f "$E2E_DOC" ]]; then
    cat >"$E2E_DOC" <<'EOF'
# YieldStream Testnet E2E Runs

This file is generated by `script/testnet-demo-with-txids.sh`.

EOF
  fi
}

append_e2e_header() {
  local run_time
  run_time="$(date -u +"%Y-%m-%d %H:%M:%S UTC")"
  ensure_e2e_doc
  cat >>"$E2E_DOC" <<EOF

## $run_time - $DESTINATION_NAME

### Infrastructure

| Item | Value |
|------|-------|
| Destination chain | \`$DESTINATION_NAME ($DESTINATION_CHAIN_ID)\` |
| Hook | \`$HOOK_ADDRESS\` |
| Lasna RSC | \`$RSC_ADDRESS\` |
| Demo token0 | \`$DEMO_TOKEN0\` |
| Demo token1 | \`$DEMO_TOKEN1\` |
| PoolManager | \`$POOL_MANAGER\` |
| Swap router | \`$SWAP_ROUTER\` |
| Lasna RSC deploy | [$RSC_DEPLOY_TX]($(lasna_tx_url "$RSC_DEPLOY_TX")) |
| Lasna subscription | [$RSC_SUBSCRIPTION_TX]($(lasna_tx_url "$RSC_SUBSCRIPTION_TX")) |

### Transactions

| Phase | Description | Tx hash | URL |
|-------|-------------|---------|-----|
EOF
}

record_e2e_tx() {
  local phase="$1"
  local description="$2"
  local tx="$3"
  local url="${4:-$(destination_tx_url "$tx")}"
  [[ -n "$tx" && "$tx" != "null" ]] || return 0
  printf '| %s | %s | `%s` | %s |\n' "$phase" "$description" "$tx" "$url" >>"$E2E_DOC"
}

append_e2e_state() {
  local epoch_id="$1"
  local fyt="$2"
  local pt="$3"
  local fees0="$4"
  local fees1="$5"
  cat >>"$E2E_DOC" <<EOF

### Result

| Item | Value |
|------|-------|
| Epoch | \`$epoch_id\` |
| FYT | \`$fyt\` |
| PT | \`$pt\` |
| Fees0 | \`$fees0\` |
| Fees1 | \`$fees1\` |

EOF
}

rnk_call() {
  local method="$1"
  local params="$2"
  curl -s --location "$LASNA_RPC_URL" \
    --header 'Content-Type: application/json' \
    --data "{\"jsonrpc\":\"2.0\",\"method\":\"$method\",\"params\":$params,\"id\":1}"
}

print_event_proofs() {
  local file="$1"
  local fees_topic
  local settled_topic
  local hash
  local receipt
  local found_fees=0
  local found_settled=0

  fees_topic="$(cast sig-event 'FeesAccrued(uint256,uint256,uint256)')"
  settled_topic="$(cast sig-event 'EpochSettled(uint256,uint256,uint256,uint256,uint256,uint256)')"

  echo
  echo "$DESTINATION_NAME event proofs"
  while read -r hash; do
    [[ -n "$hash" && "$hash" != "null" ]] || continue
    receipt="$(cast receipt "$hash" --rpc-url "$DESTINATION_RPC_URL" --json 2>/dev/null || echo '{}')"

    if jq -e --arg topic "$fees_topic" '.logs[]? | select(.topics[0] == $topic)' <<<"$receipt" >/dev/null; then
      found_fees=1
      echo "  EVENT FeesAccrued"
      echo "    txid: $hash"
      echo "    url:  $(destination_tx_url "$hash")"
      jq -r --arg topic "$fees_topic" '
        .logs[]
        | select(.topics[0] == $topic)
        | "    epoch topic: " + .topics[1] + "\n    amount0 topic: " + .topics[2]
      ' <<<"$receipt"
    fi

    if jq -e --arg topic "$settled_topic" '.logs[]? | select(.topics[0] == $topic)' <<<"$receipt" >/dev/null; then
      found_settled=1
      echo "  EVENT EpochSettled"
      echo "    txid: $hash"
      echo "    url:  $(destination_tx_url "$hash")"
      jq -r --arg topic "$settled_topic" '
        .logs[]
        | select(.topics[0] == $topic)
        | "    epoch topic: " + .topics[1]
      ' <<<"$receipt"
    fi
  done < <(jq -r '.transactions[] | .hash // empty' "$file")

  if [[ "$found_fees" == "0" ]]; then
    echo "  No FeesAccrued event found in this broadcast receipt set."
  fi
  if [[ "$found_settled" == "0" ]]; then
    echo "  No EpochSettled event found in this broadcast receipt set."
  fi
}

event_txs_from_broadcast() {
  local file="$1"
  local topic="$2"
  local hash
  local receipt

  while read -r hash; do
    [[ -n "$hash" && "$hash" != "null" ]] || continue
    receipt="$(cast receipt "$hash" --rpc-url "$DESTINATION_RPC_URL" --json 2>/dev/null || echo '{}')"
    if jq -e --arg topic "$topic" '.logs[]? | select(.topics[0] == $topic)' <<<"$receipt" >/dev/null; then
      echo "$hash"
    fi
  done < <(jq -r '.transactions[] | .hash // empty' "$file")
}

print_rnk_filter_proof() {
  local topic
  local filters
  topic="$(cast sig-event 'FeesAccrued(uint256,uint256,uint256)')"

  echo
  echo "Lasna RNK filter proof"
  filters="$(
    rnk_call "rnk_getFilters" "[]" \
      | jq --arg chain "$DESTINATION_CHAIN_ID" \
        --arg hook "$(lower "$HOOK_ADDRESS")" \
        --arg rsc "$(lower "$RSC_ADDRESS")" \
        --arg topic "$(lower "$topic")" '
          (if (.result | type) == "object" then .result.TopicFilters else .result end)[]?
          | select((.ChainId | tostring) == $chain)
          | select(((.Contract // "") | ascii_downcase) == $hook)
          | select(((.Topics[0] // "") | ascii_downcase) == $topic)
          | . as $filter
          | $filter.Configs[]
          | select((.Contract | ascii_downcase) == $rsc)
          | {
              chainId: $filter.ChainId,
              hook: $filter.Contract,
              topic0: $filter.Topics[0],
              reactiveContract: .Contract,
              rvmId: .RvmId,
              active: .Active
            }
        '
  )"
  if [[ -z "$filters" ]]; then
    echo "  No active RNK filter found for this YieldStream RSC/hook/topic." >&2
    if [[ -z "$RVM_ID" && -n "${REACTIVE_PRIVATE_KEY:-}" ]]; then
      RVM_ID="$(cast wallet address --private-key "$REACTIVE_PRIVATE_KEY")"
      echo "  Using RVM ID derived from REACTIVE_PRIVATE_KEY for transaction polling: $RVM_ID"
    fi
    return 1
  fi
  RVM_ID="$(jq -r '.rvmId' <<<"$filters" | head -n 1)"
  jq -r '
    "  chainId: " + (.chainId | tostring)
    + "\n  hook: " + .hook
    + "\n  topic0: " + .topic0
    + "\n  reactive contract: " + .reactiveContract
    + "\n  rvmId: " + .rvmId
    + "\n  active: " + (.active | tostring)
  ' <<<"$filters"
}

wait_for_rvm_tx() {
  local ref_tx="$1"
  local deadline
  local tx
  local logs
  local rvm_tx_number
  local vm_info
  local last_number
  local start_number

  deadline=$((SECONDS + REACTIVE_WAIT_SECONDS))
  echo
  echo "Waiting for ReactVM transaction for FeesAccrued tx $ref_tx..."
  if [[ -z "$RVM_ID" ]]; then
    echo "No RVM_ID is available for ReactVM transaction polling." >&2
    if [[ "$REQUIRE_REACTIVE_EVENT" == "1" ]]; then
      return 1
    fi
    return 0
  fi
  while ((SECONDS <= deadline)); do
    vm_info="$(rnk_call "rnk_getVm" "[\"$RVM_ID\"]")"
    last_number="$(jq -r '.result.lastTxNumber // "0x0"' <<<"$vm_info")"
    # RNK currently caps transaction pages at 100 results even when a larger
    # count is requested. Poll close to the current tail so fresh refTx matches
    # are not hidden behind an older capped page.
    start_number="$(printf '0x%x' "$((16#${last_number#0x} > 96 ? 16#${last_number#0x} - 96 : 0))")"
    tx="$(
      rnk_call "rnk_getTransactions" "[\"$RVM_ID\",\"$start_number\",\"0x80\"]" \
        | jq -c --arg ref "$(lower "$ref_tx")" '
          .result[]?
          | select(((.refTx // "") | ascii_downcase) == $ref)
        ' \
        | tail -n 1
    )"

    if [[ -n "$tx" ]]; then
      echo "$tx" | jq -r '
        "  RVM transaction"
        + "\n    rvm tx hash: " + .hash
        + "\n    rvm tx number: " + .number
        + "\n    status: " + (.status | tostring)
        + "\n    ref chain: " + (.refChainId | tostring)
        + "\n    ref tx: " + .refTx
      '
      rvm_tx_number="$(jq -r '.number' <<<"$tx")"
      logs="$(rnk_call "rnk_getTransactionLogs" "[\"$RVM_ID\",\"$rvm_tx_number\"]")"
      echo "  RVM logs"
      echo "$logs" | jq -r '
        .result[]?
        | "    address: " + .address
          + "\n    topic0: " + .topics[0]
          + "\n    txHash: " + .txHash
      '
      return 0
    fi

    sleep "$REACTIVE_POLL_SECONDS"
  done

  echo "No ReactVM transaction found within ${REACTIVE_WAIT_SECONDS}s for $ref_tx." >&2
  if [[ "$REQUIRE_REACTIVE_EVENT" == "1" ]]; then
    return 1
  fi
  return 0
}

poll_destination_settlement() {
  local from_block="$1"
  local topic
  local logs
  local deadline
  local callback_tx
  topic="$(cast sig-event 'EpochSettled(uint256,uint256,uint256,uint256,uint256,uint256)')"
  deadline=$((SECONDS + CALLBACK_WAIT_SECONDS))

  echo
  echo "Waiting for destination EpochSettled callback on hook $HOOK_ADDRESS..."
  while ((SECONDS <= deadline)); do
    logs="$(
      cast rpc --rpc-url "$DESTINATION_RPC_URL" eth_getLogs \
        "{\"fromBlock\":\"$(hex_quantity "$from_block")\",\"toBlock\":\"latest\",\"address\":\"$HOOK_ADDRESS\",\"topics\":[\"$topic\"]}" \
        2>/dev/null || echo "[]"
    )"

    if [[ "$(jq 'length' <<<"$logs")" != "0" ]]; then
      callback_tx="$(jq -r '.[0].transactionHash' <<<"$logs")"
      SETTLEMENT_TX="$callback_tx"
      jq -r --arg url "$(destination_tx_url "$callback_tx")" '
        .[0]
        | "  EVENT EpochSettled"
          + "\n    destination callback txid: " + .transactionHash
          + "\n    destination callback url: " + $url
          + "\n    block: " + .blockNumber
          + "\n    epoch topic: " + .topics[1]
      ' <<<"$logs"
      return 0
    fi

    sleep "$CALLBACK_POLL_SECONDS"
  done

  echo "No destination EpochSettled callback found within ${CALLBACK_WAIT_SECONDS}s."
  return 0
}

wait_for_epoch_boundary() {
  local hook="$1"
  local original_epoch="$2"
  local deadline
  local current_epoch

  deadline=$((SECONDS + YIELDSTREAM_SETTLEMENT_WAIT_SECONDS))
  echo
  echo "Waiting for hook epoch to advance beyond $original_epoch..."
  while ((SECONDS <= deadline)); do
    current_epoch="$(cast call "$hook" "currentEpoch()(uint256)" --rpc-url "$DESTINATION_RPC_URL" | awk '{print $1}')"
    if ((current_epoch > original_epoch)); then
      echo "  current epoch: $current_epoch"
      return 0
    fi
    sleep "$YIELDSTREAM_SETTLEMENT_POLL_SECONDS"
  done

  echo "Hook epoch did not advance within ${YIELDSTREAM_SETTLEMENT_WAIT_SECONDS}s."
  return 1
}

print_lasna_subscription_proof() {
  local topic
  local receipt
  topic="$(cast sig-event 'SubscriptionConfigured(uint256,address,uint256,uint256,uint256,uint256)')"
  receipt="$(cast receipt "$RSC_SUBSCRIPTION_TX" --rpc-url "$LASNA_RPC_URL" --json)"

  echo
  echo "Lasna subscription proof"
  echo "  RSC deploy txid: $RSC_DEPLOY_TX"
  echo "  RSC deploy url:  $(lasna_tx_url "$RSC_DEPLOY_TX")"
  echo "  Subscription txid: $RSC_SUBSCRIPTION_TX"
  echo "  Subscription url:  $(lasna_tx_url "$RSC_SUBSCRIPTION_TX")"
  echo "  RSC address:     $RSC_ADDRESS"
  if jq -e --arg topic "$topic" '.logs[]? | select(.topics[0] == $topic)' <<<"$receipt" >/dev/null; then
    echo "  SubscriptionConfigured event: present"
  else
    echo "  SubscriptionConfigured event: not present in RSC logs; checking RNK filter proof next"
  fi
  if [[ "$(cast call "$RSC_ADDRESS" "subscriptionConfigured()(bool)" --rpc-url "$LASNA_RPC_URL")" == "true" ]]; then
    SUBSCRIPTION_READBACK="true"
    echo "  RSC subscriptionConfigured(): true"
  else
    echo "  RSC subscriptionConfigured(): false" >&2
    if [[ "$REQUIRE_REACTIVE_EVENT" == "1" ]]; then
      exit 1
    fi
  fi
}

require_cmd cast
require_cmd jq
require_cmd curl
select_network

if [[ -z "${PRIVATE_KEY:-}" ]]; then
  echo "PRIVATE_KEY is required for the destination-chain demo broadcast." >&2
  exit 1
fi

DESTINATION_CHAIN_READ="$(cast chain-id --rpc-url "$DESTINATION_RPC_URL")"
LASNA_CHAIN_READ="$(cast chain-id --rpc-url "$LASNA_RPC_URL")"
DESTINATION_START_BLOCK="$(cast block-number --rpc-url "$DESTINATION_RPC_URL")"

if [[ "$DESTINATION_CHAIN_READ" != "$DESTINATION_CHAIN_ID" ]]; then
  echo "RPC chain mismatch: expected $DESTINATION_CHAIN_ID for $DESTINATION_NAME, got $DESTINATION_CHAIN_READ." >&2
  exit 1
fi

echo "YieldStream live testnet demo"
echo "Destination: $DESTINATION_NAME ($DESTINATION_CHAIN_ID)"
echo "Hook:        $HOOK_ADDRESS"
echo "Lasna:       chain $LASNA_CHAIN_READ"
echo "RSC:         $RSC_ADDRESS"
echo

print_lasna_subscription_proof
if ! print_rnk_filter_proof; then
  if [[ "$SUBSCRIPTION_READBACK" == "true" ]]; then
    echo "  Continuing because RSC subscriptionConfigured() is true on Lasna."
  else
    exit 1
  fi
fi

append_e2e_header
init_destination_sender

KEY_TUPLE="($DEMO_TOKEN0,$DEMO_TOKEN1,3000,60,$HOOK_ADDRESS)"
ZERO_SALT="0x0000000000000000000000000000000000000000000000000000000000000000"
MAX_UINT="115792089237316195423570985008687907853269984665640564039457584007913129639935"
MINT_AMOUNT="1000000000000000000000000"
LIQUIDITY="1000000000000000000"
MAX_DEPOSIT="10000000000000000000"
SWAP_AMOUNT="-10000000000000000"
MIN_SQRT_PLUS_ONE="4295128740"
MAX_SQRT_MINUS_ONE="1461446703485210103287273052203988822378723970341"
fees_txs=()

send_json="$(send_destination_tx "$DEMO_TOKEN0" "mint(address,uint256)" "$DEMO_SENDER" "$MINT_AMOUNT" --gas-limit 120000)"
tx="$(tx_hash_from_json <<<"$send_json")"
record_e2e_tx "Funding" "Mint demo token0 to the deployer for deposits, swaps, and fee reports." "$tx"

send_json="$(send_destination_tx "$DEMO_TOKEN1" "mint(address,uint256)" "$DEMO_SENDER" "$MINT_AMOUNT" --gas-limit 120000)"
tx="$(tx_hash_from_json <<<"$send_json")"
record_e2e_tx "Funding" "Mint demo token1 to the deployer for deposits, swaps, and fee reports." "$tx"

for token in "$DEMO_TOKEN0" "$DEMO_TOKEN1"; do
  send_json="$(send_destination_tx "$token" "approve(address,uint256)" "$HOOK_ADDRESS" "$MAX_UINT" --gas-limit 90000)"
  tx="$(tx_hash_from_json <<<"$send_json")"
  record_e2e_tx "Approval" "Approve the deployed YieldStream hook to pull $token." "$tx"

  send_json="$(send_destination_tx "$token" "approve(address,uint256)" "$SWAP_ROUTER" "$MAX_UINT" --gas-limit 90000)"
  tx="$(tx_hash_from_json <<<"$send_json")"
  record_e2e_tx "Approval" "Approve the deployed v4 swap test router to use $token." "$tx"
done

pool_configured="$(cast call "$HOOK_ADDRESS" "poolConfigured()(bool)" --rpc-url "$DESTINATION_RPC_URL" | awk '{print $1}')"
if [[ "$pool_configured" != "true" ]]; then
  send_json="$(send_destination_tx "$POOL_MANAGER" "initialize((address,address,uint24,int24,address),uint160)" "$KEY_TUPLE" 79228162514264337593543950336 --gas-limit 400000)"
  tx="$(tx_hash_from_json <<<"$send_json")"
  record_e2e_tx "Pool setup" "Initialize the reusable v4 demo pool for the deployed hook." "$tx"
else
  echo "Reusing already-configured hook pool."
fi

send_json="$(send_destination_tx "$HOOK_ADDRESS" "depositManagedLiquidity(((address,address,uint24,int24,address),int24,int24,uint128,bytes32,uint256,uint256))" "($KEY_TUPLE,-60,60,$LIQUIDITY,$ZERO_SALT,$MAX_DEPOSIT,$MAX_DEPOSIT)" --gas-limit 2500000)"
deposit_tx="$(tx_hash_from_json <<<"$send_json")"
record_e2e_tx "LP deposit" "Deposit hook-managed liquidity into the deployed YieldStream hook and mint PT/FYT for this epoch." "$deposit_tx"

managed_deposit_topic="$(cast sig-event 'ManagedLiquidityDeposited(address,uint256,bytes32,uint256,uint256,uint256)')"
deposit_receipt="$(cast receipt "$deposit_tx" --rpc-url "$DESTINATION_RPC_URL" --json)"
ORIGINAL_EPOCH_HEX="$(jq -r --arg topic "$managed_deposit_topic" '.logs[]? | select(.topics[0] == $topic) | .topics[2]' <<<"$deposit_receipt" | head -n 1)"
if [[ -z "$ORIGINAL_EPOCH_HEX" || "$ORIGINAL_EPOCH_HEX" == "null" ]]; then
  echo "Could not extract deposited epoch from ManagedLiquidityDeposited logs." >&2
  exit 1
fi
ORIGINAL_EPOCH="$(cast to-dec "$ORIGINAL_EPOCH_HEX")"
FYT_ADDRESS="$(cast call "$HOOK_ADDRESS" "getFYTContract(uint256)(address)" "$ORIGINAL_EPOCH" --rpc-url "$DESTINATION_RPC_URL")"
PT_ADDRESS="$(cast call "$HOOK_ADDRESS" "getPTContract(uint256)(address)" "$ORIGINAL_EPOCH" --rpc-url "$DESTINATION_RPC_URL")"

if [[ "$YIELDSTREAM_RUN_SWAPS" == "1" ]]; then
  send_json="$(send_destination_tx "$SWAP_ROUTER" "swap((address,address,uint24,int24,address),(bool,int256,uint160),(bool,bool),bytes)" "$KEY_TUPLE" "(false,$SWAP_AMOUNT,$MAX_SQRT_MINUS_ONE)" "(false,false)" 0x --gas-limit 900000)"
  tx="$(tx_hash_from_json <<<"$send_json")"
  record_e2e_tx "Swap" "Execute a v4 swap against the reusable demo pool during the active epoch." "$tx"
else
  echo "Skipping optional swap; reportFees emits the subscribed FeesAccrued demo event."
fi

send_json="$(send_destination_tx "$HOOK_ADDRESS" "reportFees((address,address,uint24,int24,address),uint256,uint256,uint256)" "$KEY_TUPLE" "$ORIGINAL_EPOCH" 1000000000000000 2000000000000000 --gas-limit 250000)"
fees_tx="$(tx_hash_from_json <<<"$send_json")"
fees_txs+=("$fees_tx")
record_e2e_tx "FeesAccrued" "Report active-epoch fees and emit the first FeesAccrued event observed by Lasna." "$fees_tx"
wait_for_rvm_tx "$fees_tx"

if [[ "$YIELDSTREAM_TRIGGER_SETTLEMENT_SWAP" == "1" ]]; then
  if wait_for_epoch_boundary "$HOOK_ADDRESS" "$ORIGINAL_EPOCH"; then
    send_json="$(send_destination_tx "$HOOK_ADDRESS" "reportFees((address,address,uint24,int24,address),uint256,uint256,uint256)" "$KEY_TUPLE" "$ORIGINAL_EPOCH" 3000000000000000 4000000000000000 --gas-limit 250000)"
    fees_tx="$(tx_hash_from_json <<<"$send_json")"
    fees_txs+=("$fees_tx")
    record_e2e_tx "FeesAccrued" "Report post-boundary fees against the original epoch, causing the RSC to queue settlement." "$fees_tx"
    wait_for_rvm_tx "$fees_tx"
  elif [[ "$REQUIRE_REACTIVE_EVENT" == "1" ]]; then
    exit 1
  fi
fi

if [[ "${#fees_txs[@]}" == "0" ]]; then
  echo
  echo "No FeesAccrued tx found, so there is no origin tx for Reactive Network to observe." >&2
  if [[ "$REQUIRE_REACTIVE_EVENT" == "1" ]]; then
    exit 1
  fi
fi

poll_destination_settlement "$DESTINATION_START_BLOCK"
if [[ -n "$SETTLEMENT_TX" ]]; then
  record_e2e_tx "Reactive callback" "Reactive Network submitted settleEpochFromReactive and the hook emitted EpochSettled." "$SETTLEMENT_TX"
fi

read fees0 fees1 < <(cast call "$HOOK_ADDRESS" "getEpochFees(uint256)(uint256,uint256)" "$ORIGINAL_EPOCH" --rpc-url "$DESTINATION_RPC_URL" | awk 'NR==1{a=$1} NR==2{b=$1} END{print a, b}')
append_e2e_state "$ORIGINAL_EPOCH" "$FYT_ADDRESS" "$PT_ADDRESS" "$fees0" "$fees1"

mkdir -p broadcast
jq -n \
  --arg network "$DESTINATION_NAME" \
  --argjson destinationChainId "$DESTINATION_CHAIN_ID" \
  --arg deployer "$DEMO_SENDER" \
  --arg hook "$HOOK_ADDRESS" \
  --arg rsc "$RSC_ADDRESS" \
  --arg token0 "$DEMO_TOKEN0" \
  --arg token1 "$DEMO_TOKEN1" \
  --arg fyt "$FYT_ADDRESS" \
  --arg pt "$PT_ADDRESS" \
  --argjson epochId "$ORIGINAL_EPOCH" \
  --arg fees0 "$fees0" \
  --arg fees1 "$fees1" \
  '{network:$network,destinationChainId:$destinationChainId,deployer:$deployer,hook:$hook,rsc:$rsc,token0:$token0,token1:$token1,fyt:$fyt,pt:$pt,epochId:$epochId,fees0:$fees0,fees1:$fees1}' \
  > broadcast/yieldstream-live-demo-addresses.json

echo
echo "Live demo state: broadcast/yieldstream-live-demo-addresses.json"
echo "E2E txid ledger: $E2E_DOC"
