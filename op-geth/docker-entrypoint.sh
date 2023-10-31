#!/usr/bin/env bash
set -e

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
#  wget -q -O - "${SNAPSHOT}" | tar xvf - -C /var/lib/op-geth
  cd /var/lib/op-geth/snapshot
  aria2c -c -x6 -s6 --auto-file-renaming=false --conditional-get=true --allow-overwrite=true ${SNAPSHOT}
  filename=`echo ${SNAPSHOT} | awk -F/ '{print $NF}'`
  pzstd -c -d ${filename} | tar xvf - -C /var/lib/op-geth
  rm -f ${filename}
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
  exec "$@" ${__verbosity} ${__legacy} ${EL_EXTRAS}
fi
