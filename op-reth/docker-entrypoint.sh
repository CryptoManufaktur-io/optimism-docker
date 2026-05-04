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
: "${AUTHRPC_PORT:=8551}"
: "${RPC_P2P_PORT:=30303}"
: "${EL_EXTRAS:=}"
: "${EL_INIT_EXTRAS:=}"
: "${RPC_P2P_BOOTNODES:=}"
: "${RPC_P2P_TRUSTED_NODES:=}"
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

# Public IP for NAT
__public_ip="--nat=extip:$(wget -qO- https://ifconfig.me/ip)"

# Datadir
__datadir="--datadir /var/lib/op-reth"

# Chain argument
__chain=""
if [ -n "${OPRETH_CHAIN}" ]; then
  case "${OPRETH_CHAIN}" in
    http://*|https://*)
      echo "OPRETH_CHAIN is a URL, downloading genesis file..."
      mkdir -p /data
      curl -sSL -o /data/genesis.json "${OPRETH_CHAIN}"
      __chain="--chain /data/genesis.json"
      ;;
    *)
      __chain="--chain ${OPRETH_CHAIN}"
      ;;
  esac
fi

# JWT secret
__authrpc_jwt="--authrpc.jwtsecret /var/lib/op-reth/ee-secret/jwtsecret"

# Ensure jwtsecret file exists (mounted by compose); warn if not present
if [ ! -f /var/lib/op-reth/ee-secret/jwtsecret ]; then
  echo "WARNING: JWT secret not found at /var/lib/op-reth/ee-secret/jwtsecret - op-node and op-reth require matching JWT secret for engine API."
fi

# Trusted/static nodes: if RPC_P2P_TRUSTED_NODES defined (JSON array), set --trusted-peers
__trusted_peers=""
if [ -n "${RPC_P2P_TRUSTED_NODES}" ]; then
  __peers_csv=""
  for enode in $(jq -r '.[]' <<< "${RPC_P2P_TRUSTED_NODES}"); do
    if [ -z "${__peers_csv}" ]; then
      __peers_csv="${enode}"
    else
      __peers_csv="${__peers_csv},${enode}"
    fi
  done
  if [ -n "${__peers_csv}" ]; then
    __trusted_peers="--trusted-peers=${__peers_csv}"
  fi
fi

# Bootnodes
if [ -n "${RPC_P2P_BOOTNODES}" ]; then
  __bootnodes="--bootnodes=${RPC_P2P_BOOTNODES}"
else
  __bootnodes=""
fi

# Sequencer
if [ -n "${SEQUENCER}" ]; then
  __sequencer="--rollup.sequencer-http=${SEQUENCER}"
else
  __sequencer=""
fi

# Disable txpool gossip
if [ "${DISABLE_TXPOOL_GOSSIP}" = "true" ]; then
  __disable_txpool_gossip="--rollup.disable-tx-pool-gossip --rollup.disabletxpoolgossip"
else
  __disable_txpool_gossip=""
fi

# Rollup halt
__rolluphalt=""
if [ -n "${ROLLUP_HALT}" ]; then
  if op-reth node --help 2>&1 | grep -q -- '--rollup.halt'; then
    __rolluphalt="--rollup.halt=${ROLLUP_HALT}"
  else
    echo "NOTE: This op-reth build does not support --rollup.halt; ignoring ROLLUP_HALT='${ROLLUP_HALT}'"
  fi
fi

# shellcheck disable=SC2086
echo "Launching op-reth with: $* ${__datadir} ${__chain} ${__authrpc_jwt} ${__public_ip} ${__bootnodes} ${__trusted_peers} ${__sequencer} ${__rolluphalt} ${__disable_txpool_gossip} ${EL_EXTRAS}"

# shellcheck disable=SC2086
exec "$@" ${__datadir} ${__chain} ${__authrpc_jwt} ${__public_ip} ${__bootnodes} ${__trusted_peers} ${__sequencer} ${__rolluphalt} ${__disable_txpool_gossip} ${EL_EXTRAS}
