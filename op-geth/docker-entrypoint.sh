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

# Word splitting is desired for the command line parameters
# shellcheck disable=SC2086
exec "$@" ${__verbosity} ${__pbss} ${__legacy} ${EL_EXTRAS}
