# Overview

Docker Compose for OP Stack chains: Optimism, Base, PGN, Zora.

`cp default.env .env`, then `nano .env` and adjust values for the right network including sequencer. On op-mainnet,
set a snapshot; on other networks, optionally set a snapshot.

Meant to be used with [central-proxy-docker](https://github.com/CryptoManufaktur-io/central-proxy-docker) for traefik
and Prometheus remote write; use `:ext-network.yml` in `COMPOSE_FILE` inside `.env` in that case.

If you want the op-geth RPC ports exposed locally, use `op-shared.yml` in `COMPOSE_FILE` inside `.env`.

`legacy.yml` runs the legacy l2geth on Optimism, set `LEGACY=true` in `.env` for that. You probably
[don't need it](https://community.optimism.io/docs/developers/bedrock/node-operator-guide/#historical-execution-vs-historical-data-routing).

Multiple Optimism Docker stacks all connected to the same central traefik will work, as long as they all use a
different `NETWORK`. See the `aliases` in `optimism.yml`.

The `./optd` script can be used as a quick-start:

`./optd install` brings in docker-ce, if you don't have Docker installed already.

`cp default.env .env`

`nano .env` and adjust variables as needed, particularly `NETWORK` and `SNAPSHOT` and `SEQUENCER`

`./optd up`

To update the software, run `./optd update` and then `./optd up`

# Other OP Stack chains

Optimism Docker supports OP Stack chains that are not part of the Superchain Registry, or maybe are but still
need additional parameters.

You'll want to set `NETWORK` to something unique (it cannot be empty), then set `GENESIS_URL`, `ROLLUP_URL`,
`SEQUENCER`, as well as `EL_EXTRAS`, `CL_EXTRAS`, `SYNC_MODE`, `OPGETH_P2P_BOOTNODES` and `OPNODE_P2P_BOOTNODES` as needed.

Some example values by chain are below

## Worldchain

`NETWORK=worldchain-mainnet`
`SEQUENCER=https://worldchain-mainnet-sequencer.g.alchemy.com`
`EL_EXTRAS="--override.fjord=1721826000 --override.granite=1727780400 --override.ecotone=0 --override.canyon=0"`
`CL_EXTRAS="--override.fjord=1721826000 --override.granite=1727780400 --override.ecotone=0 --override.canyon=0 --sequencer.l1-confs=10 --verifier.l1-confs=10 --l1.trustrpc=true"`
`OPNODE_SYNC_MODE=execution-layer`
`GENESIS_URL="https://raw.githubusercontent.com/worldcoin/world-id-docs/refs/heads/main/public/code/world-chain/genesis.json"`
`ROLLUP_URL="https://raw.githubusercontent.com/worldcoin/world-id-docs/refs/heads/main/public/code/world-chain/rollup.json"`
`OPGETH_P2P_BOOTNODES="enode://dd4e44e87d68dd43bfc16d4fd5d9a6a2cd428986f75ddf15c8a72add0ad425852b9c36b6c5999ab7a37cc64d9bc1b68d549bc088dfa728e84dea7ae617f64e04@107.22.23.212:0?discport=30301,enode://47bd99d0bc393c6ca5569058b2d031067a3df5d05214036a5b88c9b817d52e08d7514d452b1aa623cfb3dd415136dcaf90c962e62d9337ff511fee0e9d1c8b28@18.207.96.148:0?discport=30301"`

# Version

This is Optimism Docker v3.2.0
