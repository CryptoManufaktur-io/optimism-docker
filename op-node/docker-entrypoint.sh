#!/usr/bin/env bash
set -Eeuo pipefail

if [[ ! -f /var/lib/op-node/ee-secret/jwtsecret ]]; then
  echo "Generating JWT secret"
  __secret1=$(head -c 8 /dev/urandom | od -A n -t u8 | tr -d '[:space:]' | sha256sum | head -c 32)
  __secret2=$(head -c 8 /dev/urandom | od -A n -t u8 | tr -d '[:space:]' | sha256sum | head -c 32)
  echo -n "${__secret1}""${__secret2}" > /var/lib/op-node/ee-secret/jwtsecret
fi

if [[ -O "/var/lib/op-node/ee-secret/jwtsecret" ]]; then
  chmod 666 /var/lib/op-node/ee-secret/jwtsecret
fi

__public_ip="--p2p.advertise.ip $(wget -qO- https://ifconfig.me/ip)"

if [ -n "${ROLLUP_URL}" ]; then
  mkdir -p /var/lib/op-node/config
# We use Notion links and this may fail
  set +e
  curl \
    --fail \
    --show-error \
    --silent \
    --retry-connrefused \
    --retry-all-errors \
    --retry 5 \
    --retry-delay 5 \
    "${ROLLUP_URL}" \
    -o /var/lib/op-node/config/rollup.json
  set -e


  if [ ! -f /var/lib/op-node/config/rollup.json ]; then
    echo "No rollup.json found, this is fatal. Please check your download link for it in .env"
    exit 1
  fi
  __network="--rollup.config=/var/lib/op-node/config/rollup.json"
else
  __network="--network=${NETWORK}"
fi

if [ -n "${OPNODE_P2P_BOOTNODES}" ]; then
  __bootnodes="p2p.bootnodes=${OPNODE_P2P_BOOTNODES}"
else
  __bootnodes=""
fi


if [ -n "${OPNODE_P2P_STATIC_PEERS}" ]; then
  __staticpeers="p2p.static=${OPNODE_P2P_STATIC_PEERS}"
else
  __staticpeers=""
fi
# Word splitting is desired for the command line parameters
# shellcheck disable=SC2086
exec "$@" ${__public_ip} ${__network} ${__bootnodes} ${__static_peers} ${CL_EXTRAS}
