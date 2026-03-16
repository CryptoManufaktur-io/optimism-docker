#!/bin/sh
set -e

if [ -n "$EIGENDA_PROXY_ENDPOINT" ]; then
  echo "Not starting local EigenDA proxy since proxy endpoint ($EIGENDA_PROXY_ENDPOINT) is defined"
  exit
fi

if [ -n "$EIGENDA_LOCAL_ARCHIVE_BLOBS" ]; then
  export EXTENDED_EIGENDA_PARAMETERS="${EXTENDED_EIGENDA_PARAMETERS:-} --s3.credential-type=$EIGENDA_LOCAL_S3_CREDENTIAL_TYPE \
  --s3.access-key-id=$EIGENDA_LOCAL_S3_ACCESS_KEY_ID \
  --s3.access-key-secret=$EIGENDA_LOCAL_S3_ACCESS_KEY_SECRET \
  --s3.bucket=$EIGENDA_LOCAL_S3_BUCKET \
  --s3.path=$EIGENDA_LOCAL_S3_PATH \
  --s3.endpoint=$EIGENDA_LOCAL_S3_ENDPOINT \
  --storage.fallback-targets=s3"
fi

exec ./eigenda-proxy --addr=0.0.0.0 \
  --port=4242 \
  --eigenda.disperser-rpc="$EIGENDA_LOCAL_DISPERSER_RPC" \
  --eigenda.eth-rpc="$OP_NODE__RPC_ENDPOINT" \
  --eigenda.svc-manager-addr="$EIGENDA_LOCAL_SVC_MANAGER_ADDR" \
  --eigenda.disable-tls=false \
  --eigenda.max-blob-length="16MiB" \
  --storage.backends-to-enable="V1,V2" \
  --eigenda.v2.eth-rpc="$OP_NODE__RPC_ENDPOINT" \
  --eigenda.v2.disable-tls=false \
  --eigenda.v2.blob-certified-timeout="2m" \
  --eigenda.v2.contract-call-timeout="5s" \
  --eigenda.v2.relay-timeout="5s" \
  --eigenda.v2.max-blob-length="16MiB" \
  --eigenda.v2.network="$EIGENDA_V2_LOCAL_NETWORK" \
  --eigenda.v2.cert-verifier-router-or-immutable-verifier-addr="$EIGENDA_V2_LOCAL_CERT_VERIFIER_ROUTER_ADDR" \
  --apis.enabled="op-generic,op-keccak,standard,metrics" \
  $EXTENDED_EIGENDA_PARAMETERS
