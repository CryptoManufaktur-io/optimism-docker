#!/usr/bin/env bash
set -euo pipefail

DATADIR=/var/lib/op-reth
JWT=/var/lib/op-reth/ee-secret/jwtsecret

: "${OPRETH_CHAIN:=celo}"
: "${SEQUENCER:=}"
: "${RPC_P2P_BOOTNODES:=}"
: "${RPC_P2P_TRUSTED_NODES:=}"
: "${NODE_TYPE:=archive}"     # minimal | full | archive
: "${OP_RETH_SNAPSHOT:=true}" # bootstrap from snapshots.celo.org
: "${RPC_PORT:=8545}"
: "${WS_PORT:=8546}"
: "${RPC_P2P_PORT:=30303}"
: "${EL_EXTRAS:=}"

if [ -d "${DATADIR}/geth" ]; then
  echo "ERROR: ${DATADIR} contains op-geth data. celo-reth needs an empty datadir." >&2
  exit 1
fi

if [ "${OP_RETH_SNAPSHOT}" = "true" ] && [ ! -d "${DATADIR}/db" ]; then
  echo "No data in ${DATADIR}; downloading --${NODE_TYPE} snapshot for chain=${OPRETH_CHAIN}..."
  celo-reth download --datadir="${DATADIR}" --chain="${OPRETH_CHAIN}" "--${NODE_TYPE}"
fi

__public_ip="--nat=extip:$(wget -qO- https://ifconfig.me/ip)"

__prune=""
if [ "${NODE_TYPE}" != "archive" ]; then
  __prune="--${NODE_TYPE}"
fi

__bootnodes=""
[ -n "${RPC_P2P_BOOTNODES}" ] && __bootnodes="--bootnodes=${RPC_P2P_BOOTNODES}"

__trusted=""
[ -n "${RPC_P2P_TRUSTED_NODES}" ] && __trusted="--trusted-peers=${RPC_P2P_TRUSTED_NODES}"

__sequencer=""
[ -n "${SEQUENCER}" ] && __sequencer="--rollup.sequencer=${SEQUENCER}"

# shellcheck disable=SC2086
exec celo-reth node \
  --chain="${OPRETH_CHAIN}" \
  --datadir="${DATADIR}" \
  --storage.v2=true \
  --http --http.addr=0.0.0.0 --http.port="${RPC_PORT}" --http.corsdomain="*" \
  --http.api=web3,eth,txpool,net \
  --ws --ws.addr=0.0.0.0 --ws.port="${WS_PORT}" --ws.origins="*" \
  --ws.api=eth,txpool,net,web3 \
  --authrpc.addr=0.0.0.0 --authrpc.port=8551 --authrpc.jwtsecret="${JWT}" \
  --metrics=0.0.0.0:6060 \
  --port="${RPC_P2P_PORT}" --discovery.port="${RPC_P2P_PORT}" --discovery.v5.port="${RPC_P2P_PORT}" \
  --max-peers=100 \
  --txpool.nolocals --rpc.txfeecap=0 \
  --rollup.disable-tx-pool-gossip \
  ${__public_ip} ${__prune} ${__bootnodes} ${__trusted} ${__sequencer} ${EL_EXTRAS} \
  -vvv
