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
RVM_ID="${RVM_ID:-}"

require_cmd() {
  if ! command -v "$1" >/dev/null 2>&1; then
    echo "Missing required command: $1" >&2
    exit 1
  fi
}

lower() {
  printf "%s" "$1" | tr '[:upper:]' '[:lower:]'
}

select_network() {
  case "$NETWORK" in
    base|base-sepolia|base_sepolia)
      NETWORK_NAME="base-sepolia"
      DESTINATION_RPC_URL="${BASE_SEPOLIA_RPC_URL:?BASE_SEPOLIA_RPC_URL is required}"
      DESTINATION_CHAIN_ID="84532"
      HOOK_ADDRESS="${BASE_SEPOLIA_YIELDSTREAM_HOOK_DEMO:-${BASE_SEPOLIA_YIELDSTREAM_HOOK:?BASE_SEPOLIA_YIELDSTREAM_HOOK is required}}"
      RSC_ADDRESS="${BASE_SEPOLIA_YIELDSTREAM_RSC_DEMO:-${BASE_SEPOLIA_YIELDSTREAM_RSC_LATEST:-0x180896366174318f5BD64d8320576A488400115a}}"
      CALLBACK_PROXY="${BASE_SEPOLIA_CALLBACK_PROXY:?BASE_SEPOLIA_CALLBACK_PROXY is required}"
      ;;
    unichain|unichain-sepolia|unichain_sepolia)
      NETWORK_NAME="unichain-sepolia"
      DESTINATION_RPC_URL="${UNICHAIN_SEPOLIA_RPC_URL:?UNICHAIN_SEPOLIA_RPC_URL is required}"
      DESTINATION_CHAIN_ID="1301"
      HOOK_ADDRESS="${UNICHAIN_SEPOLIA_YIELDSTREAM_HOOK_DEMO:-${UNICHAIN_SEPOLIA_YIELDSTREAM_HOOK:?UNICHAIN_SEPOLIA_YIELDSTREAM_HOOK is required}}"
      RSC_ADDRESS="${UNICHAIN_SEPOLIA_YIELDSTREAM_RSC_DEMO:-${UNICHAIN_SEPOLIA_YIELDSTREAM_RSC_LATEST:-0x55b29D0ba5B35C3fDcD81bD6f40eACECc15C4035}}"
      CALLBACK_PROXY="${UNICHAIN_SEPOLIA_CALLBACK_PROXY:?UNICHAIN_SEPOLIA_CALLBACK_PROXY is required}"
      ;;
    *)
      echo "Unsupported YIELDSTREAM_E2E_NETWORK='$NETWORK'. Use base or unichain." >&2
      exit 1
      ;;
  esac
}

require_cmd cast
select_network

if [[ -z "$RVM_ID" ]]; then
  if [[ -n "${REACTIVE_PRIVATE_KEY:-}" ]]; then
    RVM_ID="$(cast wallet address --private-key "$REACTIVE_PRIVATE_KEY")"
  else
    echo "Set RVM_ID or REACTIVE_PRIVATE_KEY so the verifier can check callback auth." >&2
    exit 1
  fi
fi

echo "YieldStream Reactive integration check"
echo "Destination: $NETWORK_NAME ($DESTINATION_CHAIN_ID)"
echo "Hook:        $HOOK_ADDRESS"
echo "RSC:         $RSC_ADDRESS"
echo "RVM ID:      $RVM_ID"
echo

echo "Lasna RSC readback"
cast call "$RSC_ADDRESS" "DESTINATION_CHAIN_ID()(uint256)" --rpc-url "$LASNA_RPC_URL"
cast call "$RSC_ADDRESS" "HOOK_ADDRESS()(address)" --rpc-url "$LASNA_RPC_URL"
cast call "$RSC_ADDRESS" "CALLBACK_GAS_LIMIT()(uint64)" --rpc-url "$LASNA_RPC_URL"
cast call "$RSC_ADDRESS" "FEES_ACCRUED_TOPIC()(uint256)" --rpc-url "$LASNA_RPC_URL"
echo

echo "Destination hook readback"
cast call "$HOOK_ADDRESS" "callbackProxy()(address)" --rpc-url "$DESTINATION_RPC_URL"
cast call "$HOOK_ADDRESS" "reactiveSender()(address)" --rpc-url "$DESTINATION_RPC_URL"
cast call "$HOOK_ADDRESS" "owner()(address)" --rpc-url "$DESTINATION_RPC_URL"
echo

actual_destination="$(cast call "$RSC_ADDRESS" "DESTINATION_CHAIN_ID()(uint256)" --rpc-url "$LASNA_RPC_URL" | awk '{print $1}')"
actual_hook="$(cast call "$RSC_ADDRESS" "HOOK_ADDRESS()(address)" --rpc-url "$LASNA_RPC_URL")"
actual_proxy="$(cast call "$HOOK_ADDRESS" "callbackProxy()(address)" --rpc-url "$DESTINATION_RPC_URL")"
actual_sender="$(cast call "$HOOK_ADDRESS" "reactiveSender()(address)" --rpc-url "$DESTINATION_RPC_URL")"

[[ "$actual_destination" == "$DESTINATION_CHAIN_ID" ]] || { echo "Bad RSC destination chain"; exit 1; }
[[ "$(lower "$actual_hook")" == "$(lower "$HOOK_ADDRESS")" ]] || { echo "Bad RSC hook address"; exit 1; }
[[ "$(lower "$actual_proxy")" == "$(lower "$CALLBACK_PROXY")" ]] || { echo "Bad hook callback proxy"; exit 1; }
[[ "$(lower "$actual_sender")" == "$(lower "$RVM_ID")" ]] || { echo "Bad hook reactive sender; expected RVM ID"; exit 1; }

echo "Reactive integration check passed."
