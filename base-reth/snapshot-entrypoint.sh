#!/usr/bin/env bash
# ./op-reth/docker-entrypoint.sh
set -euo pipefail
shopt -s nocasematch

# Debug toggle
if [ "${DEBUG:-false}" = "true" ]; then
  set -x
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
