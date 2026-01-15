#!/usr/bin/env bash
set -euo pipefail

CONTAINER="ink-op-geth-1"
LOCAL_RPC="http://127.0.0.1:8545"
PUBLIC_RPC="https://rpc-gel.inkonchain.com"

# Acceptable lag in blocks before failing as "still syncing"
BLOCK_LAG_THRESHOLD=2

# ETA sampling window (seconds)
SAMPLE_SECS=10

hex_to_dec() { printf "%d" "$((16#${1#0x}))"; }

rpc_post() {
  # args: rpc_url, json_payload
  local rpc="$1"
  local payload="$2"
  docker exec "$CONTAINER" sh -c "
    curl -sS -X POST '$rpc' \
      -H 'Content-Type: application/json' \
      --data '$payload'
  "
}

jq_in_container() {
  docker exec -i "$CONTAINER" jq -r "$1"
}

echo "==> Ensuring curl and jq are installed inside container"

docker exec -u root "$CONTAINER" sh -c '
set -e
if command -v curl >/dev/null 2>&1 && command -v jq >/dev/null 2>&1; then
  exit 0
fi

if command -v apt-get >/dev/null 2>&1; then
  apt-get update -y
  apt-get install -y curl jq ca-certificates
elif command -v apk >/dev/null 2>&1; then
  apk add --no-cache curl jq ca-certificates
else
  echo "Unsupported base image. No apt-get or apk found."
  exit 1
fi
'

echo "==> Checking local geth eth_syncing status"

syncing_json="$(rpc_post "$LOCAL_RPC" '{"jsonrpc":"2.0","method":"eth_syncing","params":[],"id":1}')"
syncing_result="$(echo "$syncing_json" | jq_in_container '.result | @json')"

# syncing_result here is a JSON-encoded string of result. Handle "false" and objects.
# If result is false, @json produces "false" (a JSON string containing false). For objects, it produces a JSON string.
if [[ -z "$syncing_result" || "$syncing_result" == "null" ]]; then
  echo "❌ Could not parse eth_syncing response. Raw response:"
  echo "$syncing_json"
  exit 5
fi

# Strip surrounding quotes if present (jq @json returns a JSON string)
syncing_unquoted="$(printf '%s' "$syncing_result" | sed -e 's/^"//' -e 's/"$//')"

if [[ "$syncing_unquoted" == "false" ]]; then
  echo "eth_syncing: false (not actively syncing)"
else
  echo "eth_syncing: true (actively syncing)"
  # Try to print common geth fields if present
  startingBlock="$(printf '%s' "$syncing_unquoted" | docker exec -i "$CONTAINER" jq -r '.startingBlock // empty' 2>/dev/null || true)"
  currentBlock="$(printf '%s' "$syncing_unquoted"  | docker exec -i "$CONTAINER" jq -r '.currentBlock  // empty' 2>/dev/null || true)"
  highestBlock="$(printf '%s' "$syncing_unquoted"  | docker exec -i "$CONTAINER" jq -r '.highestBlock  // empty' 2>/dev/null || true)"

  if [[ -n "${startingBlock:-}" || -n "${currentBlock:-}" || -n "${highestBlock:-}" ]]; then
    if [[ "${startingBlock:-}" == 0x* ]]; then startingBlock="$(hex_to_dec "$startingBlock")"; fi
    if [[ "${currentBlock:-}"  == 0x* ]]; then currentBlock="$(hex_to_dec "$currentBlock")"; fi
    if [[ "${highestBlock:-}"  == 0x* ]]; then highestBlock="$(hex_to_dec "$highestBlock")"; fi
    echo "  startingBlock: ${startingBlock:-?}"
    echo "  currentBlock:  ${currentBlock:-?}"
    echo "  highestBlock:  ${highestBlock:-?}"
  else
    echo "  (sync details not provided in this client response)"
  fi
fi

echo
echo "==> Querying local and public heads (eth_blockNumber) and estimating ETA"

local_bn_json="$(rpc_post "$LOCAL_RPC" '{"jsonrpc":"2.0","method":"eth_blockNumber","params":[],"id":1}')"
public_bn_json="$(rpc_post "$PUBLIC_RPC" '{"jsonrpc":"2.0","method":"eth_blockNumber","params":[],"id":1}')"

local_bn_hex="$(echo "$local_bn_json"  | jq_in_container '.result')"
public_bn_hex="$(echo "$public_bn_json" | jq_in_container '.result')"

if [[ "$local_bn_hex" == "null" || -z "$local_bn_hex" ]]; then
  echo "❌ Local eth_blockNumber invalid. Raw response:"
  echo "$local_bn_json"
  exit 6
fi

if [[ "$public_bn_hex" == "null" || -z "$public_bn_hex" ]]; then
  echo "❌ Public eth_blockNumber invalid. Raw response:"
  echo "$public_bn_json"
  exit 7
fi

local_bn_dec="$(hex_to_dec "$local_bn_hex")"
public_bn_dec="$(hex_to_dec "$public_bn_hex")"
remaining="$((public_bn_dec - local_bn_dec))"

echo "Local  head:    $local_bn_dec"
echo "Public head:    $public_bn_dec"
echo "Remaining:      $remaining blocks"

echo "==> Sampling local head rate for ~${SAMPLE_SECS}s"
sleep "$SAMPLE_SECS"

local_bn_json_2="$(rpc_post "$LOCAL_RPC" '{"jsonrpc":"2.0","method":"eth_blockNumber","params":[],"id":1}')"
local_bn_hex_2="$(echo "$local_bn_json_2" | jq_in_container '.result')"
local_bn_dec_2="$(hex_to_dec "$local_bn_hex_2")"

delta="$((local_bn_dec_2 - local_bn_dec))"
echo "Advanced:       $delta blocks in ${SAMPLE_SECS}s"

if (( delta <= 0 )); then
  echo "ETA:            unknown (local head not advancing yet)"
else
  bps="$((delta / SAMPLE_SECS))"
  if (( bps <= 0 )); then
    echo "ETA:            unknown (rate < 1 block/sec over sample window)"
  else
    eta_secs="$((remaining / bps))"
    eta_mins="$((eta_secs / 60))"
    echo "Rate:           ~${bps} blocks/sec"
    echo "ETA to head:    ~${eta_mins} minutes (very rough)"
  fi
fi

echo
echo "==> Querying local and public latest blocks (height + hash)"

local_json="$(rpc_post "$LOCAL_RPC" '{"jsonrpc":"2.0","method":"eth_getBlockByNumber","params":["latest",false],"id":1}')"
public_json="$(rpc_post "$PUBLIC_RPC" '{"jsonrpc":"2.0","method":"eth_getBlockByNumber","params":["latest",false],"id":1}')"

local_num="$(echo "$local_json"  | jq_in_container '.result.number')"
local_hash="$(echo "$local_json" | jq_in_container '.result.hash')"

public_num="$(echo "$public_json"  | jq_in_container '.result.number')"
public_hash="$(echo "$public_json" | jq_in_container '.result.hash')"

if [[ "$local_num" == "null" || "$local_hash" == "null" || -z "$local_num" || -z "$local_hash" ]]; then
  echo "❌ Local RPC returned no block data (number/hash null). Raw response:"
  echo "$local_json"
  exit 3
fi

if [[ "$public_num" == "null" || "$public_hash" == "null" || -z "$public_num" || -z "$public_hash" ]]; then
  echo "❌ Public RPC returned no block data (number/hash null). Raw response:"
  echo "$public_json"
  exit 4
fi

local_dec="$(hex_to_dec "$local_num")"
public_dec="$(hex_to_dec "$public_num")"
lag="$((public_dec - local_dec))"

echo
echo "Local   block: $local_dec  $local_hash"
echo "Public  block: $public_dec $public_hash"
echo "Lag:          $lag blocks (threshold: $BLOCK_LAG_THRESHOLD)"
echo

if [[ "$local_num" == "$public_num" && "$local_hash" == "$public_hash" ]]; then
  echo "✅ Node is in sync (height and hash match)"
  exit 0
fi

if (( lag > BLOCK_LAG_THRESHOLD )); then
  echo "⚠️  Heights differ beyond threshold. Still syncing."
  exit 1
fi

if [[ "$local_num" == "$public_num" && "$local_hash" != "$public_hash" ]]; then
  echo "❌ Heights match but hashes differ. Possible reorg or divergence."
  exit 2
fi

echo "⚠️  Heights differ but within threshold. Likely normal propagation lag."
exit 0
