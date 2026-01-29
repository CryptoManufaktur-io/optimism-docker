#!/usr/bin/env bash
# ./op-reth/docker-entrypoint.sh
set -euo pipefail
shopt -s nocasematch

# Debug toggle
if [ "${DEBUG:-false}" = "true" ]; then
  set -x
fi

# --- Logging level mapping (Rust)
case "${LOG_LEVEL:-info}" in
  error) export RUST_LOG="${RUST_LOG:-error}" ;;
  warn)  export RUST_LOG="${RUST_LOG:-warn}" ;;
  info)  export RUST_LOG="${RUST_LOG:-info}" ;;
  debug) export RUST_LOG="${RUST_LOG:-debug}" ;;
  trace) export RUST_LOG="${RUST_LOG:-trace}" ;;
  *)     export RUST_LOG="${RUST_LOG:-info}" ;;
esac

# Default env var fallbacks
: "${NETWORK:=}"
: "${GENESIS_URL:=}"
: "${OPRETH_CHAIN:=}"
: "${RPC_PORT:=8545}"
: "${WS_PORT:=8546}"
: "${OPRETH_P2P_PORT:=30304}"
: "${AUTHRPC_PORT:=8551}"
: "${EL_EXTRAS:=}"
: "${EL_INIT_EXTRAS:=}"
: "${OPRETH_P2P_BOOTNODES:=}"
: "${OPRETH_P2P_TRUSTED_NODES:=}"
: "${DISABLE_TXPOOL_GOSSIP:=false}"
: "${SEQUENCER:=}"
: "${ROLLUP_HALT:=}"
: "${GENESIS_URL:=}"

# If GENESIS_URL provided and datadir empty -> init with genesis.
if [ -n "${GENESIS_URL}" ] && [ ! -d "/var/lib/op-reth/db" ] && [ ! -d "/var/lib/op-reth/chaindata" ]; then
  echo "Initializing op-reth datadir from GENESIS_URL..."
  if [[ "${GENESIS_URL}" == file://* ]]; then
    LOCAL_PATH="${GENESIS_URL#file://}"
    cp "${LOCAL_PATH}" /tmp/genesis.json
  else
    wget -qO /tmp/genesis.json "${GENESIS_URL}"
  fi

  if command -v op-reth >/dev/null 2>&1; then
    if op-reth --help 2>&1 | grep -q -e 'genesis' -e 'init' ; then
      echo "Attempting to initialize chain (op-reth genesis/db init)..."
      set +e

      # shellcheck disable=SC2086
      op-reth db init --data-dir /var/lib/op-reth --genesis /tmp/genesis.json ${EL_INIT_EXTRAS} 2>/dev/null || true
      # shellcheck disable=SC2086
      op-reth genesis import --data-dir /var/lib/op-reth /tmp/genesis.json ${EL_INIT_EXTRAS} 2>/dev/null || true

      set -e
    else
      echo "op-reth binary does not advertise a genesis/import helper; leaving genesis.json in /var/lib/op-reth"
      mv /tmp/genesis.json /var/lib/op-reth/genesis.json
    fi
  fi
fi

# Trusted/static nodes: if OPRETH_P2P_TRUSTED_NODES defined (JSON array), attempt to produce a static-nodes file
if [ -n "${OPRETH_P2P_TRUSTED_NODES:-}" ]; then
  echo "Writing trusted/static nodes to /var/lib/op-reth/static-nodes.json"
  # Expect OPRETH_P2P_TRUSTED_NODES as JSON array like ["enode://...","enode://..."]
  echo "${OPRETH_P2P_TRUSTED_NODES}" | jq -c '.' > /var/lib/op-reth/static-nodes.json || true
fi

# Bootnodes forwarded to flags if set
__bootnodes=""
if [ -n "${OPRETH_P2P_BOOTNODES:-}" ]; then
  __bootnodes="--bootnodes=${OPRETH_P2P_BOOTNODES}"
fi

# Sequencer forwarding if set
__sequencer=""
if [ -n "${SEQUENCER:-}" ]; then
  __sequencer="--rollup.sequencer-http=${SEQUENCER}"
fi

# Disable txpool gossip mapping
if [ "${DISABLE_TXPOOL_GOSSIP:-false}" = "true" ]; then
  # append both syntaxes safely in the extras variable (version-tolerant)
  EL_EXTRAS="${EL_EXTRAS} --rollup.disable-tx-pool-gossip --rollup.disabletxpoolgossip"
fi

# Implement ROLLUP_HALT: add --rollup.halt=<value> unless user already supplied it
__rolluphalt=""
if [ -n "${ROLLUP_HALT:-}" ]; then
  if op-reth node --help 2>&1 | grep -q -- '--rollup.halt'; then
    __rolluphalt="--rollup.halt=${ROLLUP_HALT}"
  else
    echo "NOTE: This op-reth build does not support --rollup.halt; ignoring ROLLUP_HALT='${ROLLUP_HALT}'"
  fi
fi

# Ensure jwtsecret file exists (mounted by compose); warn if not present
if [ ! -f /var/lib/op-reth/ee-secret/jwtsecret ]; then
  echo "WARNING: JWT secret not found at /var/lib/op-reth/ee-secret/jwtsecret - op-node and op-reth require matching JWT secret for engine API."
fi

# Build final argv list (starting from compose-provided args)
ARGS=( "$@" )

# If user didn't provide --datadir, prefer /var/lib/op-reth
if [[ ! " ${ARGS[*]} " =~ " --datadir " ]]; then
  ARGS+=( --datadir /var/lib/op-reth )
fi

# Default chain argument if not provided; prefer OPRETH_CHAIN env var
if [[ ! " ${ARGS[*]} " =~ " --chain " ]] && [ -n "${OPRETH_CHAIN}" ]; then
  ARGS+=( --chain "${OPRETH_CHAIN}" )
fi

# RPC/WS/authrpc default ports unless overridden in ARGS
if [[ ! " ${ARGS[*]} " =~  --http\.port  ]]; then
  ARGS+=( --http.port "${RPC_PORT}" )
fi
if [[ ! " ${ARGS[*]} " =~  --ws\.port  ]]; then
  ARGS+=( --ws.port "${WS_PORT}" )
fi
if [[ ! " ${ARGS[*]} " =~  --authrpc\.port  ]]; then
  ARGS+=( --authrpc.port "${AUTHRPC_PORT}" )
fi
if [[ ! " ${ARGS[*]} " =~  --port  ]]; then
  ARGS+=( --port "${OPRETH_P2P_PORT}" )
fi

# authrpc jwt secret path
if [[ ! " ${ARGS[*]} " =~  --authrpc\.jwtsecret  ]]; then
  ARGS+=( --authrpc.jwtsecret /var/lib/op-reth/ee-secret/jwtsecret )
fi

# Add bootnodes & sequencer flags if not already present
if [ -n "${__bootnodes}" ] && [[ ! " ${ARGS[*]} " =~  --bootnodes  ]]; then
  # shellcheck disable=SC2086
  ARGS+=( "${__bootnodes}" )
fi
if [ -n "${__sequencer}" ] && [[ ! " ${ARGS[*]} " =~  --rollup\.sequencer ]]; then
  # shellcheck disable=SC2086
  ARGS+=( "${__sequencer}" )
fi

# Add rollup halt if supported and not already present
if [ -n "${__rolluphalt}" ]; then
  if [[ ! " ${ARGS[*]} " =~  --rollup\.halt ]] && [[ "${EL_EXTRAS}" != *"--rollup.halt"* ]]; then
    # shellcheck disable=SC2086
    ARGS+=( "${__rolluphalt}" )
  fi
fi

# Append extras last
if [ -n "${EL_EXTRAS:-}" ]; then
  # shellcheck disable=SC2086
  ARGS+=( "${EL_EXTRAS}" )
fi

echo "Launching op-reth with:"
echo "  ENTRYPOINT: $0"
echo "  CMD args: ${ARGS[*]}"

exec "${ARGS[@]}"