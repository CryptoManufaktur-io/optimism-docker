#!/bin/sh
set -euo pipefail

exec ./eigenda-proxy --addr=0.0.0.0 \
  --port=4242 \
  --eigenda.disperser-rpc="$EIGENDA_LOCAL_DISPERSER_RPC" \
  --eigenda.eth-rpc="$OP_NODE__RPC_ENDPOINT" \
  --eigenda.signer-private-key-hex=$(head -c 32 /dev/urandom | xxd -p -c 32) \
  --eigenda.svc-manager-addr="$EIGENDA_LOCAL_SVC_MANAGER_ADDR" \
  --eigenda.status-query-timeout="45m" \
  --eigenda.disable-tls=false \
  --eigenda.confirmation-depth=1 \
  --eigenda.max-blob-length="32MiB"
