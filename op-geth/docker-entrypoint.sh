#!/usr/bin/env bash
set -euo pipefail

# Set verbosity
shopt -s nocasematch
case ${LOG_LEVEL} in
  error)
    __verbosity="--verbosity 1"
    ;;
  warn)
    __verbosity="--verbosity 2"
    ;;
  info)
    __verbosity="--verbosity 3"
    ;;
  debug)
    __verbosity="--verbosity 4"
    ;;
  trace)
    __verbosity="--verbosity 5"
    ;;
  *)
    echo "LOG_LEVEL ${LOG_LEVEL} not recognized"
    __verbosity=""
    ;;
esac

__public_ip="--nat=extip:$(wget -qO- https://ifconfig.me/ip)"

if [ -n "${GENESIS_URL}" ]; then
  __network=""
  if [ ! -d "/var/lib/op-geth/geth/" ]; then
    echo "Initializing geth datadir from genesis.json"
    wget $GENESIS_URL -O genesis.json
    geth init --datadir=/var/lib/op-geth --state.scheme path genesis.json
  fi
else
  __network="--op-network=${NETWORK}"
fi

# Detect existing DB; use PBSS if fresh
if [ -d "/var/lib/op-geth/geth/chaindata/" ]; then
  __pbss=""
else
  echo "Choosing PBSS for fresh sync"
  __pbss="--state.scheme path"
fi

# Run with legacy l2geth?
if [ "${LEGACY}" = true ]; then
  __legacy="--rollup.historicalrpc http://l2geth:8545"
else
  __legacy=""
fi

if [ -n "${OPGETH_P2P_BOOTNODES}" ]; then
  __bootnodes="--bootnodes=${OPGETH_P2P_BOOTNODES}"
else
  __bootnodes=""
fi

if [ -n "${SEQUENCER}" ]; then
  __sequencer="--rollup.sequencerhttp=${SEQUENCER}"
else
  __sequencer=""
fi

if [ -n "${ROLLUP_HALT}" ]; then
  __rolluphalt="--rollup.halt=${ROLLUP_HALT}"
else
  __rolluphalt=""
fi

# Word splitting is desired for the command line parameters
# shellcheck disable=SC2086
exec "$@" ${__verbosity} ${__network} ${__public_ip} ${__pbss} ${__bootnodes} ${__rolluphalt} ${__legacy} ${__sequencer} ${EL_EXTRAS}
