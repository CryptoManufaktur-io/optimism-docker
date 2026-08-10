#!/usr/bin/env bash
# ./op-reth/docker-entrypoint.sh
set -euo pipefail
shopt -s nocasematch

# Debug toggle
if [ "${DEBUG:-false}" = "true" ]; then
  set -x
fi

# Ensure required dirs exist
mkdir -p /var/lib/op-reth/ee-secret

# Generate JWT secret
if [[ ! -f /var/lib/op-reth/ee-secret/jwtsecret ]]; then
  echo "Generating JWT secret for op-reth"
  __secret1=$(head -c 8 /dev/urandom | od -A n -t u8 | tr -d '[:space:]' | sha256sum | head -c 32)
  __secret2=$(head -c 8 /dev/urandom | od -A n -t u8 | tr -d '[:space:]' | sha256sum | head -c 32)
  echo -n "${__secret1}${__secret2}" > /var/lib/op-reth/ee-secret/jwtsecret
fi

if [[ -O "/var/lib/op-reth/ee-secret/jwtsecret" ]]; then
  chmod 666 /var/lib/op-reth/ee-secret/jwtsecret
fi


if [[ -f /var/lib/op-reth/done-snapshot.txt ]]; then
  echo "No snapshot fetch necessary"
  exit 0
else
  echo "Downloading snapshot using"
fi

# shellcheck disable=SC2086
exec "$@"

touch /var/lib/op-reth/done-snapshot.txt
