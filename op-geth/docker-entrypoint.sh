#!/usr/bin/env bash
set -euo pipefail

if [[ ! -f /var/lib/op-geth/ee-secret/jwtsecret ]]; then
  echo "Generating JWT secret"
  __secret1=$(head -c 8 /dev/urandom | od -A n -t u8 | tr -d '[:space:]' | sha256sum | head -c 32)
  __secret2=$(head -c 8 /dev/urandom | od -A n -t u8 | tr -d '[:space:]' | sha256sum | head -c 32)
  echo -n "${__secret1}""${__secret2}" > /var/lib/op-geth/ee-secret/jwtsecret
fi

if [[ -O "/var/lib/op-geth/ee-secret/jwtsecret" ]]; then
  chmod 666 /var/lib/op-geth/ee-secret/jwtsecret
fi

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

# Prep datadir
if [ -n "${SNAPSHOT}" ] && [ ! -d "/var/lib/op-geth/geth/" ]; then
  __dont_rm=0
  cd /var/lib/op-geth/snapshot
  eval "__url=${SNAPSHOT}"
  aria2c -c -x6 -s6 --auto-file-renaming=false --conditional-get=true --allow-overwrite=true "${__url}"
  filename=$(echo "${__url}" | awk -F/ '{print $NF}')
  if [[ "${filename}" =~ \.tar\.zst$ ]]; then
    pzstd -c -d "${filename}" | tar xvf - -C /var/lib/op-geth
  elif [[ "${filename}" =~ \.tar\.gz$ || "${filename}" =~ \.tgz$ ]]; then
    tar xzvf "${filename}" -C /var/lib/op-geth
  elif [[ "${filename}" =~ \.tar$ ]]; then
    tar xvf "${filename}" -C /var/lib/op-geth
  elif [[ "${filename}" =~ \.lz4$ ]]; then
    tar -I lz4 xvf "${filename}" -C /var/lib/op-geth
  else
    __dont_rm=1
    echo "The snapshot file has a format that Optimism Docker can't handle."
    echo "Please come to CryptoManufaktur Discord to work through this."
  fi
  if [ "${__dont_rm}" -eq 0 ]; then
    rm -f "${filename}"
  fi
  if [[ -d /var/lib/op-geth/data/geth/chaindata ]]; then # Base format
    mv /var/lib/op-geth/data/geth /var/lib/op-geth/
    rm -rf /var/lib/op-geth/data
  elif [[ -d /var/lib/op-geth/op-dir/geth/chaindata ]]; then # Fastnode format
    mv /var/lib/op-geth/op-dir/geth /var/lib/op-geth/
    rm -rf /var/lib/op-geth/op-dir
  elif [[ -d /var/lib/op-geth/chaindata ]]; then # hypothetical
    mkdir -p /var/lib/op-geth/geth
    mv /var/lib/op-geth/chaindata /var/lib/op-geth/geth/
  fi
  if [[ ! -d /var/lib/op-geth/geth/chaindata ]]; then
    echo "Chaindata isn't in the expected location."
    echo "This snapshot likely won't work until the entrypoint script has been adjusted for it."
  fi
fi

if [[ -z "${SNAPSHOT}" && ( "${NETWORK}" = "op-goerli" || "${NETWORK}" = "op-mainnet" ) ]]; then
  echo "WARNING: Optimism Goerli and Optimism Mainnet should be using a SNAPSHOT in .env"
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

if [ -f /var/lib/op-geth/prune-marker ]; then
  rm -f /var/lib/op-geth/prune-marker
  exec "$@" snapshot prune-state
else
# Word splitting is desired for the command line parameters
# shellcheck disable=SC2086
  exec "$@" ${__verbosity} ${__pbss} ${__legacy} ${EL_EXTRAS}
fi
