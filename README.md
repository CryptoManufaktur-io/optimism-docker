# Overview

docker compose for Bedrock Optimism. Copy default.env to .env, adjust values for the right network, particularly the snapshot

Meant to be used with https://github.com/CryptoManufaktur-io/base-docker-environment for traefik and Prometheus remote write;
use ext-network.yml in that case

If you want the op-geth RPC ports exposed locally, use `op-shared.yml` in `COMPOSE_FILE` inside `.env`

legacy.yml runs the legacy l2geth, set `LEGACY=true` in `.env` for that as well
