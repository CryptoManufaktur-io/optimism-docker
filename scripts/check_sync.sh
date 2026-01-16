#!/usr/bin/env bash
set -euo pipefail

usage() {
  cat <<'EOF'
Usage: check_sync.sh [options]

Options:
  --container NAME         Docker container name or ID to run curl/jq within
  --compose-service NAME   Docker Compose service name to resolve to a container
  --local-rpc URL          Local RPC URL (default: http://127.0.0.1:${RPC_PORT:-8545})
  --public-rpc URL         Public/reference RPC URL (required)
  --block-lag N            Acceptable lag in blocks (default: 2)
  --sample-secs N          ETA sampling window in seconds (default: 10)
  --no-install             Do not install curl/jq inside the container
  --env-file PATH          Path to env file to load
  -h, --help               Show this help

Examples:
  ./check_sync.sh --public-rpc https://mainnet.optimism.io
  ./check_sync.sh --compose-service op-geth --public-rpc https://mainnet.optimism.io
  CONTAINER=op-geth-1 PUBLIC_RPC=https://mainnet.optimism.io ./check_sync.sh
EOF
}

ENV_FILE="${ENV_FILE:-}"
CONTAINER="${CONTAINER:-}"
DOCKER_SERVICE="${DOCKER_SERVICE:-}"
LOCAL_RPC="${LOCAL_RPC:-}"
PUBLIC_RPC="${PUBLIC_RPC:-}"
BLOCK_LAG_THRESHOLD="${BLOCK_LAG_THRESHOLD:-2}"
SAMPLE_SECS="${SAMPLE_SECS:-10}"
INSTALL_TOOLS="${INSTALL_TOOLS:-1}"

load_env_file() {
  local file="$1"
  [[ -f "$file" ]] || return 0
  while IFS= read -r line || [[ -n "$line" ]]; do
    line="${line#"${line%%[![:space:]]*}"}"
    [[ -z "$line" || "$line" == \#* ]] && continue
    line="${line#export }"
    if [[ "$line" =~ ^[A-Za-z_][A-Za-z0-9_]*= ]]; then
      local key="${line%%=*}"
      local val="${line#*=}"
      val="${val#"${val%%[![:space:]]*}"}"
      if [[ "$val" =~ ^\".*\"$ ]]; then
        val="${val:1:-1}"
      elif [[ "$val" =~ ^\'.*\'$ ]]; then
        val="${val:1:-1}"
      fi
      printf -v "$key" '%s' "$val"
      export "${key?}"
    fi
  done < "$file"
}

args=("$@")
for ((i=0; i<${#args[@]}; i++)); do
  if [[ "${args[$i]}" == "--env-file" ]]; then
    ENV_FILE="${args[$((i+1))]:-}"
  fi
done

if [[ -n "${ENV_FILE:-}" ]]; then
  load_env_file "$ENV_FILE"
fi

while [[ $# -gt 0 ]]; do
  case "$1" in
    --container) CONTAINER="$2"; shift 2 ;;
    --compose-service) DOCKER_SERVICE="$2"; shift 2 ;;
    --local-rpc) LOCAL_RPC="$2"; shift 2 ;;
    --public-rpc) PUBLIC_RPC="$2"; shift 2 ;;
    --block-lag) BLOCK_LAG_THRESHOLD="$2"; shift 2 ;;
    --sample-secs) SAMPLE_SECS="$2"; shift 2 ;;
    --no-install) INSTALL_TOOLS="0"; shift ;;
    --env-file) ENV_FILE="$2"; shift 2 ;;
    -h|--help) usage; exit 0 ;;
    *) echo "Unknown option: $1"; usage; exit 2 ;;
  esac
done

LOCAL_RPC="${LOCAL_RPC:-http://127.0.0.1:${RPC_PORT:-8545}}"
PUBLIC_RPC="${PUBLIC_RPC:-}"

hex_to_dec() { printf "%d" "$((16#${1#0x}))"; }

resolve_container() {
  if [[ -n "$CONTAINER" || -z "$DOCKER_SERVICE" ]]; then
    return 0
  fi
  if ! command -v docker >/dev/null 2>&1; then
    echo "❌ docker not found; cannot resolve --compose-service $DOCKER_SERVICE"
    exit 2
  fi
  if docker compose version >/dev/null 2>&1; then
    CONTAINER="$(docker compose ps -q "$DOCKER_SERVICE" | head -n 1)"
  elif command -v docker-compose >/dev/null 2>&1; then
    CONTAINER="$(docker-compose ps -q "$DOCKER_SERVICE" | head -n 1)"
  else
    echo "❌ docker compose not available; cannot resolve --compose-service $DOCKER_SERVICE"
    exit 2
  fi
}

rpc_post() {
  # args: rpc_url, json_payload
  local rpc="$1"
  local payload="$2"
  if [[ -n "$CONTAINER" ]]; then
    docker exec "$CONTAINER" sh -c "
      curl -sS -X POST '$rpc' \
        -H 'Content-Type: application/json' \
        --data '$payload'
    "
  else
    curl -sS -X POST "$rpc" \
      -H 'Content-Type: application/json' \
      --data "$payload"
  fi
}

jq_eval() {
  if [[ -n "$CONTAINER" ]]; then
    docker exec -i "$CONTAINER" jq -r "$1"
  else
    jq -r "$1"
  fi
}

resolve_container

if [[ -z "$PUBLIC_RPC" ]]; then
  echo "❌ PUBLIC_RPC is required. Use --public-rpc or set PUBLIC_RPC."
  exit 2
fi

if [[ -n "$CONTAINER" ]]; then
  if [[ "$INSTALL_TOOLS" == "1" ]]; then
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
  fi
else
  if ! command -v curl >/dev/null 2>&1 || ! command -v jq >/dev/null 2>&1; then
    echo "❌ curl and jq are required on the host when no --container is set."
    exit 2
  fi
fi

echo "==> Checking local geth eth_syncing status"

syncing_json="$(rpc_post "$LOCAL_RPC" '{"jsonrpc":"2.0","method":"eth_syncing","params":[],"id":1}')"
syncing_result="$(echo "$syncing_json" | jq_eval '.result | @json')"

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
  startingBlock="$(printf '%s' "$syncing_unquoted" | jq_eval '.startingBlock // empty' 2>/dev/null || true)"
  currentBlock="$(printf '%s' "$syncing_unquoted"  | jq_eval '.currentBlock  // empty' 2>/dev/null || true)"
  highestBlock="$(printf '%s' "$syncing_unquoted"  | jq_eval '.highestBlock  // empty' 2>/dev/null || true)"

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

local_bn_hex="$(echo "$local_bn_json"  | jq_eval '.result')"
public_bn_hex="$(echo "$public_bn_json" | jq_eval '.result')"

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
local_bn_hex_2="$(echo "$local_bn_json_2" | jq_eval '.result')"
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

local_num="$(echo "$local_json"  | jq_eval '.result.number')"
local_hash="$(echo "$local_json" | jq_eval '.result.hash')"

public_num="$(echo "$public_json"  | jq_eval '.result.number')"
public_hash="$(echo "$public_json" | jq_eval '.result.hash')"

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
