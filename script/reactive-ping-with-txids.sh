#!/usr/bin/env bash
set -euo pipefail

if [[ -f .env ]]; then
  set -a
  # shellcheck disable=SC1091
  source .env
  set +a
fi

NETWORK="${YIELDSTREAM_E2E_NETWORK:-base}"
LASNA_RPC_URL="${LASNA_RPC_URL:-${REACTIVE_RPC:-https://lasna-rpc.rnk.dev/}}"
REACTIVE_WAIT_SECONDS="${REACTIVE_WAIT_SECONDS:-240}"
REACTIVE_POLL_SECONDS="${REACTIVE_POLL_SECONDS:-6}"
CALLBACK_WAIT_SECONDS="${CALLBACK_WAIT_SECONDS:-240}"
CALLBACK_POLL_SECONDS="${CALLBACK_POLL_SECONDS:-6}"
PING_SKIP_DESTINATION_DEPLOY="${PING_SKIP_DESTINATION_DEPLOY:-0}"
PING_SKIP_RSC_DEPLOY="${PING_SKIP_RSC_DEPLOY:-0}"
RVM_ID=""

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
      CALLBACK_PROXY="${BASE_SEPOLIA_CALLBACK_PROXY:?BASE_SEPOLIA_CALLBACK_PROXY is required}"
      ;;
    unichain|unichain-sepolia|unichain_sepolia)
      NETWORK="unichain"
      DESTINATION_NAME="unichain-sepolia"
      DESTINATION_RPC_URL="${UNICHAIN_SEPOLIA_RPC_URL:?UNICHAIN_SEPOLIA_RPC_URL is required}"
      DESTINATION_CHAIN_ID="1301"
      CALLBACK_PROXY="${UNICHAIN_SEPOLIA_CALLBACK_PROXY:?UNICHAIN_SEPOLIA_CALLBACK_PROXY is required}"
      ;;
    *)
      echo "Unsupported YIELDSTREAM_E2E_NETWORK='$NETWORK'. Use base or unichain." >&2
      exit 1
      ;;
  esac
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

print_rnk_filter_proof() {
  local topic
  local filters
  topic="$(cast sig-event 'Ping(uint256,address,uint256)')"

  echo
  echo "Lasna RNK filter proof"
  filters="$(
    curl -s --location "$LASNA_RPC_URL" \
      --header 'Content-Type: application/json' \
      --data '{"jsonrpc":"2.0","method":"rnk_getFilters","params":[],"id":1}' \
      | jq --arg chain "$DESTINATION_CHAIN_ID" \
        --arg origin "$(lower "$PING_ORIGIN_ADDRESS")" \
        --arg rsc "$(lower "$PING_RSC_ADDRESS")" \
        --arg topic "$(lower "$topic")" '
          (if (.result | type) == "object" then .result.TopicFilters else .result end)[]?
          | select((.ChainId | tostring) == $chain)
          | select(((.Contract // "") | ascii_downcase) == $origin)
          | select(((.Topics[0] // "") | ascii_downcase) == $topic)
          | . as $filter
          | $filter.Configs[]
          | select((.Contract | ascii_downcase) == $rsc)
          | {
              chainId: $filter.ChainId,
              origin: $filter.Contract,
              topic0: $filter.Topics[0],
              reactiveContract: .Contract,
              rvmId: .RvmId,
              active: .Active
            }
        '
  )"
  if [[ -z "$filters" ]]; then
    echo "  No active RNK filter found for this ping RSC/origin/topic." >&2
    return 1
  fi
  RVM_ID="$(jq -r '.rvmId' <<<"$filters" | head -n 1)"
  jq -r '
    "  chainId: " + (.chainId | tostring)
    + "\n  origin: " + .origin
    + "\n  topic0: " + .topic0
    + "\n  reactive contract: " + .reactiveContract
    + "\n  rvmId: " + .rvmId
    + "\n  active: " + (.active | tostring)
  ' <<<"$filters"
}

rnk_call() {
  local method="$1"
  local params="$2"
  curl -s --location "$LASNA_RPC_URL" \
    --header 'Content-Type: application/json' \
    --data "{\"jsonrpc\":\"2.0\",\"method\":\"$method\",\"params\":$params,\"id\":1}"
}

wait_for_rvm_tx() {
  local ref_tx="$1"
  local deadline
  local tx
  local logs

  deadline=$((SECONDS + REACTIVE_WAIT_SECONDS))
  echo
  echo "Waiting for ReactVM transaction for origin tx $ref_tx..."
  while ((SECONDS <= deadline)); do
    tx="$(
      rnk_call "rnk_getTransactions" "[\"$RVM_ID\",\"0x0\",\"0x800\"]" \
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
      RVM_TX_NUMBER="$(jq -r '.number' <<<"$tx")"
      RVM_TX_HASH="$(jq -r '.hash' <<<"$tx")"
      logs="$(rnk_call "rnk_getTransactionLogs" "[\"$RVM_ID\",\"$RVM_TX_NUMBER\"]")"
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

  echo "No ReactVM transaction found within ${REACTIVE_WAIT_SECONDS}s." >&2
  return 1
}

require_cmd forge
require_cmd cast
require_cmd jq
require_cmd curl
select_network

if [[ -z "${PRIVATE_KEY:-}" ]]; then
  echo "PRIVATE_KEY is required for destination-chain transactions." >&2
  exit 1
fi
if [[ -z "${REACTIVE_PRIVATE_KEY:-}" && "$PING_SKIP_RSC_DEPLOY" != "1" ]]; then
  echo "REACTIVE_PRIVATE_KEY is required to deploy the Lasna ping RSC." >&2
  exit 1
fi

DESTINATION_CHAIN_READ="$(cast chain-id --rpc-url "$DESTINATION_RPC_URL")"
LASNA_CHAIN_ID="$(cast chain-id --rpc-url "$LASNA_RPC_URL")"
LASNA_START_BLOCK="$(cast block-number --rpc-url "$LASNA_RPC_URL")"
DESTINATION_CALLBACK_START_BLOCK="$(cast block-number --rpc-url "$DESTINATION_RPC_URL")"

if [[ "$DESTINATION_CHAIN_READ" != "$DESTINATION_CHAIN_ID" ]]; then
  echo "RPC chain mismatch: expected $DESTINATION_CHAIN_ID for $DESTINATION_NAME, got $DESTINATION_CHAIN_READ." >&2
  exit 1
fi

echo "Reactive ping proof"
echo "Destination: $DESTINATION_NAME ($DESTINATION_CHAIN_ID)"
echo "Lasna:       chain $LASNA_CHAIN_ID"
echo "Callback proxy: $CALLBACK_PROXY"

if [[ "$PING_SKIP_DESTINATION_DEPLOY" == "1" ]]; then
  PING_ORIGIN_ADDRESS="${PING_ORIGIN_ADDRESS:?PING_ORIGIN_ADDRESS is required when skipping destination deploy}"
  PING_RECEIVER_ADDRESS="${PING_RECEIVER_ADDRESS:?PING_RECEIVER_ADDRESS is required when skipping destination deploy}"
else
  CALLBACK_PROXY="$CALLBACK_PROXY" \
    RUST_LOG=error forge script script/DeployReactivePingDestination.s.sol:DeployReactivePingDestination \
    --rpc-url "$DESTINATION_RPC_URL" \
    --private-key "$PRIVATE_KEY" \
    --broadcast \
    -vvv

  DESTINATION_DEPLOY_JSON="broadcast/DeployReactivePingDestination.s.sol/$DESTINATION_CHAIN_ID/run-latest.json"
  print_hashes "$DESTINATION_NAME ping destination deployment txids" "$DESTINATION_DEPLOY_JSON"
  PING_ORIGIN_ADDRESS="$(
    jq -r '.transactions[] | select(.contractName == "ReactivePingOrigin") | .contractAddress' "$DESTINATION_DEPLOY_JSON"
  )"
  PING_RECEIVER_ADDRESS="$(
    jq -r '.transactions[] | select(.contractName == "ReactivePingReceiver") | .contractAddress' "$DESTINATION_DEPLOY_JSON"
  )"
fi

echo
echo "Ping origin:   $PING_ORIGIN_ADDRESS"
echo "Ping receiver: $PING_RECEIVER_ADDRESS"

if [[ "$PING_SKIP_RSC_DEPLOY" == "1" ]]; then
  PING_RSC_ADDRESS="${PING_RSC_ADDRESS:?PING_RSC_ADDRESS is required when skipping RSC deploy}"
else
  DESTINATION_CHAIN_ID="$DESTINATION_CHAIN_ID" \
    PING_ORIGIN_ADDRESS="$PING_ORIGIN_ADDRESS" \
    PING_RECEIVER_ADDRESS="$PING_RECEIVER_ADDRESS" \
    RUST_LOG=error forge script script/DeployReactivePingRSC.s.sol:DeployReactivePingRSC \
    --rpc-url "$LASNA_RPC_URL" \
    --private-key "$REACTIVE_PRIVATE_KEY" \
    --broadcast \
    -vvv

  RSC_DEPLOY_JSON="broadcast/DeployReactivePingRSC.s.sol/$LASNA_CHAIN_ID/run-latest.json"
  print_hashes "Lasna ping RSC deployment txids" "$RSC_DEPLOY_JSON"
  PING_RSC_ADDRESS="$(
    jq -r '.transactions[] | select(.contractName == "ReactivePingRSC") | .contractAddress' "$RSC_DEPLOY_JSON"
  )"
fi

echo
echo "Ping RSC: $PING_RSC_ADDRESS"
print_rnk_filter_proof

PING_ORIGIN_ADDRESS="$PING_ORIGIN_ADDRESS" \
  RUST_LOG=error forge script script/SendReactivePing.s.sol:SendReactivePing \
  --rpc-url "$DESTINATION_RPC_URL" \
  --private-key "$PRIVATE_KEY" \
  --broadcast \
  -vvv

PING_JSON="broadcast/SendReactivePing.s.sol/$DESTINATION_CHAIN_ID/run-latest.json"
print_hashes "$DESTINATION_NAME ping txids" "$PING_JSON"

PING_TX="$(jq -r '.transactions[] | select(.hash != null) | .hash' "$PING_JSON" | tail -n 1)"
echo "  ping url: $(destination_tx_url "$PING_TX")"

wait_for_rvm_tx "$PING_TX"

echo
echo "Waiting for destination PingCallbackReceived on receiver $PING_RECEIVER_ADDRESS..."
callback_topic="$(cast sig-event 'PingCallbackReceived(address,address,uint256,uint256)')"
deadline=$((SECONDS + CALLBACK_WAIT_SECONDS))
callback_tx=""
while ((SECONDS <= deadline)); do
  logs="$(
    cast rpc --rpc-url "$DESTINATION_RPC_URL" eth_getLogs \
      "{\"fromBlock\":\"$(hex_quantity "$DESTINATION_CALLBACK_START_BLOCK")\",\"toBlock\":\"latest\",\"address\":\"$PING_RECEIVER_ADDRESS\",\"topics\":[\"$callback_topic\"]}" \
      2>/dev/null || echo "[]"
  )"
  if [[ "$(jq 'length' <<<"$logs")" != "0" ]]; then
    callback_tx="$(jq -r '.[0].transactionHash' <<<"$logs")"
    injected_topic="$(jq -r '.[0].topics[1]' <<<"$logs")"
    injected_sender="0x${injected_topic:26}"
    jq -r --arg url "$(destination_tx_url "$callback_tx")" --arg injected "$injected_sender" '
      .[0]
      | "  EVENT PingCallbackReceived"
        + "\n    destination txid: " + .transactionHash
        + "\n    destination url: " + $url
        + "\n    injected sender: " + $injected
        + "\n    callback caller topic: " + .topics[2]
    ' <<<"$logs"
    break
  fi
  sleep "$CALLBACK_POLL_SECONDS"
done

if [[ -z "$callback_tx" ]]; then
  echo "No destination PingCallbackReceived log found within ${CALLBACK_WAIT_SECONDS}s." >&2
  exit 1
fi

echo
echo "Reactive ping proof complete."
