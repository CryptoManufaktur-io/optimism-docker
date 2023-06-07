# Overview

docker compose for Bedrock Optimism.

Copy `default.env` to `.env`, adjust values for the right network, particularly the snapshot.

Meant to be used with https://github.com/CryptoManufaktur-io/base-docker-environment for traefik and Prometheus remote write;
use `ext-network.yml` in that case

If you want the op-geth RPC ports exposed locally, use `op-shared.yml` in `COMPOSE_FILE` inside `.env`

`legacy.yml` runs the legacy l2geth, set `LEGACY=true` in `.env` for that. You probably [don't need it](https://community.optimism.io/docs/developers/bedrock/node-operator-guide/#historical-execution-vs-historical-data-routing).

The `./ethd` script can be used as a quick-start:

`./ethd install` brings in docker-ce, if you don't have a Docker install already.

`cp default.env .env`

Adjust variables as needed, particularly `NETWORK` and `SNAPSHOT`

`./ethd up`

To update the software, run `./ethd update` and then `./ethd up`

This is optimism-docker v1.0.1
