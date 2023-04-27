#!/usr/bin/env bash
set -e

if [[ ! -f /var/lib/op-geth/ee-secret/jwtsecret ]]; then
  echo "Generating JWT secret"
  __secret1=$(echo $RANDOM | md5sum | head -c 32)
  __secret2=$(echo $RANDOM | md5sum | head -c 32)
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
if [ ! -d "/var/lib/op-geth/geth/" ]; then
  wget -q -O - "${SNAPSHOT}" | tar xvf - -C /var/lib/op-geth
fi

# Run with legacy l2geth?
if [ "${LEGACY}" = true ]; then
  __legacy="--rollup.historicalrpc http://l2geth:8545"
else
  __legacy=""
fi
# Word splitting is desired for the command line parameters
# shellcheck disable=SC2086
exec "$@" ${__verbosity} ${__legacy}
