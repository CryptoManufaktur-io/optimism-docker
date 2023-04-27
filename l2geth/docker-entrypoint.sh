#!/usr/bin/env bash
set -e

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
if [ ! -d "/var/lib/l2geth/geth/" ]; then
  wget -q -O - "${LEGACY_TAR}" | tar xvf - -C /var/lib/l2geth
fi

# Word splitting is desired for the command line parameters
# shellcheck disable=SC2086
exec "$@" ${__verbosity}
