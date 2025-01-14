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

## B^2

```
NETWORK=b2
OPNODE_DOCKER_TAG=v1.7.7
OPGETH_DOCKER_TAG=v1.101315.2
SNAPSHOT=https://download.bsquared.network/db.tar.gz
SEQUENCER=https://b2-mainnet.alt.technology/
L1_RPC=https://hub-rpc.bsquared.network
L1_BEACON=https://hub-cl-rpc.bsquared.network
EL_EXTRAS="--syncmode=full --snapshot=false"
CL_EXTRAS="--verifier.l1-confs=10 --sequencer.l1-confs=10 --l1.trustrpc=true"
OPNODE_SYNC_MODE=execution-layer
GENESIS_URL="https://download.bsquared.network/mainnet/genesis.json"
ROLLUP_URL="https://download.bsquared.network/mainnet/rollup.json"
OPGETH_P2P_BOOTNODES=enode://55b79017f15cad10bb8ad433fb991e6a0d0ca5ccef3f9123618869ee405d61b564a44dee1b87c47e62dba51e63a9172e356714a7ecdf20594d041ddf9013136c@b2-mainnet-geth-p2p.altlayer.network:30303,enode://7ddd900597dde5cca6508cf33264dd528b945563d3d6ff5d0d2b16ecf8e14ca92ebf44fdabe9ecef44532aa0caeb54945c7d40af9d5a08e4b81853308a91ed27@b2-mainnet-bootnode1.bsquared.network:30303,enode://01c15b6db86024b708a3f3e2cdea2769264bc81dc8997752b44b904daff98f2ca15ca1e3096ed601debe7ad0f057c12d30bf93aeaeb227a59443059402c57dec@b2-mainnet-bootnode2.bsquared.network:30303
OPNODE_P2P_STATIC_PEERS=/dns/b2-mainnet-node-p2p.altlayer.network/tcp/9003/p2p/16Uiu2HAm1hkacTvu8HzwPs2Mv8cHo6RfMX9vbEi4T8FuXFRK7VEM,/dns/b2-mainnet-bootnode1.bsquared.network/tcp/9222/p2p/16Uiu2HAkwyquyg55Jnmo97czvXfB6Evove1C4jUdMoFRQEQkgbnn,/dns/b2-mainnet-bootnode2.bsquared.network/tcp/9222/p2p/16Uiu2HAmSP44jYc7aJVXJhKVoYUFqkotwpEU1zqxYCksvUWwcyFT
```

## Blast

```
NETWORK=blast
OPGETH_DOCKER_TAG=v1.1.0-mainnet
OPNODE_DOCKER_TAG=v1.1.0-mainnet
OPGETH_DOCKER_REPO=blastio/blast-geth
OPNODE_DOCKER_REPO=blastio/blast-optimism
SEQUENCER=https://sequencer.blast.io
OPNODE_SYNC_MODE=consensus-layer
CL_EXTRAS=--l1.trustrpc
EL_EXTRAS=--syncmode=full --nodiscover --maxpeers=0 --override.ecotone=1716843599 --override.canyon=0
GENESIS_URL=https://raw.githubusercontent.com/blast-io/deployment/master/mainnet/genesis.json
ROLLUP_URL=https://raw.githubusercontent.com/blast-io/deployment/master/mainnet/rollup.json
OPNODE_P2P_BOOTNODES=enr:-J64QGwHl9uYLfC_cnmxSA6wQH811nkOWJDWjzxqkEUlJoZHWvI66u-BXgVcPCeMUmg0dBpFQAPotFchG67FHJMZ9OSGAY3d6wevgmlkgnY0gmlwhANizeSHb3BzdGFja4Sx_AQAiXNlY3AyNTZrMaECg4pk0cskPAyJ7pOmo9E6RqGBwV-Lex4VS9a3MQvu7PWDdGNwgnZhg3VkcIJ2YQ,enr:-J64QDge2jYBQtcNEpRqmKfci5E5BHAhNBjgv4WSdwH1_wPqbueq2bDj38-TSW8asjy5lJj1Xftui6Or8lnaYFCqCI-GAY3d6wf3gmlkgnY0gmlwhCO2D9yHb3BzdGFja4Sx_AQAiXNlY3AyNTZrMaEDo4aCTq7pCEN8om9U5n_VyWdambGnQhwHNwKc8o-OicaDdGNwgnZhg3VkcIJ2YQ
```

## BoB

```
NETWORK=bob
SEQUENCER=https://rpc.gobob.xyz
EL_EXTRAS="--override.fjord=1720627201 --override.granite=1726070401"
CL_EXTRAS="--override.fjord=1720627201 --override.granite=1726070401 --l1.trustrpc=true"
OPNODE_SYNC_MODE=execution-layer
GENESIS_URL="https://raw.githubusercontent.com/CryptoManufaktur-io/optimism-docker/refs/heads/main/config/bob/genesis.json"
ROLLUP_URL="https://raw.githubusercontent.com/CryptoManufaktur-io/optimism-docker/refs/heads/main/config/bob/rollup.json"
OPGETH_P2P_BOOTNODES=enode://09acd29625beb40604b12b1c2194d6d5eb290aee03e0149675201ed717ce226c506671f46fcd440ce6f5e62dc4e059ffe88bcd931f2febcd22520ae7b9d00b5e@34.83.120.192:9222?discport=30301,enode://d25ce99435982b04d60c4b41ba256b84b888626db7bee45a9419382300fbe907359ae5ef250346785bff8d3b9d07cd3e017a27e2ee3cfda3bcbb0ba762ac9674@bootnode.conduit.xyz:0?discport=30301,enode://2d4e7e9d48f4dd4efe9342706dd1b0024681bd4c3300d021f86fc75eab7865d4e0cbec6fbc883f011cfd6a57423e7e2f6e104baad2b744c3cafaec6bc7dc92c1@34.65.43.171:0?discport=30305,enode://9d7a3efefe442351217e73b3a593bcb8efffb55b4807699972145324eab5e6b382152f8d24f6301baebbfb5ecd4127bd3faab2842c04cd432bdf50ba092f6645@34.65.109.126:0?discport=30305
OPNODE_P2P_STATIC_PEERS=/ip4/34.83.120.192/tcp/9222/p2p/16Uiu2HAkv5SVdeF4hFqJyCATwT87S3PZmutm8akrgwfcdFeqNxWw
```

## Ink

Ink provides a [snapshot](https://storage.googleapis.com/raas-op-geth-snapshots-e2025/datadir-archive/latest), which
is optional. It can be synced from Genesis, but is faster from snapshot.

Ink's snapshot link gives you a path, which should be combined with
`https://storage.googleapis.com/raas-op-geth-snapshots-e2025/datadir-archive/` to get a full URL.

```
NETWORK=ink-mainnet
SNAPSHOT=https://storage.googleapis.com/raas-op-geth-snapshots-e2025/datadir-archive/<current-snapshot-path>
SEQUENCER=https://rpc-gel.inkonchain.com
CL_EXTRAS=--l1.trustrpc=true --p2p.scoring=none
EL_EXTRAS=--syncmode=snap --maxpeers=0 --networkid=57073 --nodiscover --gpo.percentile=60 --txlookuplimit=0 --history.state=0 --history.transactions=0 --txpool.pricebump=10 --txpool.lifetime=12h0m0s --rpc.txfeecap=4 --rpc.evmtimeout=0
OPNODE_SYNC_MODE=consensus-layer
GENESIS_URL=https://raw.githubusercontent.com/inkonchain/node/refs/heads/main/envs/ink-mainnet/config/genesis.json
ROLLUP_URL=https://raw.githubusercontent.com/inkonchain/node/refs/heads/main/envs/ink-mainnet/config/rollup.json
OPNODE_P2P_BOOTNODES=enr:-Iu4QCqTQZVBnbPWXcdUxcakGoCCzCFr5vVzDfNTOr-Pi3KaOJZMXlnqTR9r9p4EemXS8fS59EdQaX8qrkyE01nvsNcBgmlkgnY0gmlwhCIgwYaJc2VjcDI1NmsxoQMW3w0F1AibYelKqJUKaie5RuKc7S9sPfWvH4lSJw4Fo4N0Y3CCIyuDdWRwgiMs
OPNODE_P2P_STATIC_PEERS=/ip4/34.32.193.134/tcp/9003/p2p/16Uiu2HAmECGb1vmBKhgxVHzX2aYkPcmV8CZjpPxrNkRiFA1wa3CN
```

## Hashkey

```
NETWORK=hashkeychain-mainnet
SEQUENCER=https://mainnet.hsk.xyz
CL_EXTRAS=--l1.trustrpc --l1.beacon.ignore --safedb.path /var/lib/op-node/safedb --verifier.l1-confs=15 --sequencer.l1-confs=15
EL_EXTRAS=---syncmode=full --gcmode=full
INIT_STATE_SCHEME: hash
OPNODE_SYNC_MODE=execution-layer
GENESIS_URL=https://operator-public.s3.us-west-2.amazonaws.com/hashkeychain/mainnet/genesis.json
ROLLUP_URL=https://operator-public.s3.us-west-2.amazonaws.com/hashkeychain/mainnet/rollup.json
OPNODE_P2P_BOOTNODES: ""
OPGETH_P2P_BOOTNODES=enode://e3d83751cba1f5fd806a73e9701baaa93eb729474eb6c246050e76f9cde32915d4904e1fa12be4196ad7296aba61d4ffebfb7a9c5eeff2b9578e0d7a55cc5ed5@mainnet-mux-aws.altlayer.network:31419,enode://b3714bf5e75760fcbb4de393b75bbcf046be7aa6fb47bd928c4ad6405717a5e67cb01a31dc820ce6b51cfb6c8268ec6c1166fdb2a66f9c92ea67f2fdfdf130fc@mainnet-mux-aws.altlayer.network:31371,enode://6ad0903b679bed251393813042f2452f55ec4e6f120347d412c203072e58bb2e3c1d68247eba25a89b920995bed3b043819d49577a8c1fe4f1c0d762d7d6763a@mainnet-mux-aws.altlayer.network:30250,enode://17162151981152707b855e1e67ab9027dcad7af7a2dbcfa40352c6940f1a977f490b2522986736a8c20327abd5f50afd39f23031b3b103d99c0c03c4449bd172@mainnet-mux-aws.altlayer.network:30924
OPNODE_P2P_STATIC_PEERS=/dns/mainnet-mux-aws.altlayer.network/tcp/30678/p2p/16Uiu2HAm1UX8Lx4XKnHXncKCw5Q4r6jsajKDEukHk9S9NXuroVKY,/dns/mainnet-mux-aws.altlayer.network/tcp/32307/p2p/16Uiu2HAm2PzcWR3pgBkCSUC8Co6WsKHhyyxJysQqzeZpHoX2RaAf,/dns/mainnet-mux-aws.altlayer.network/tcp/32441/p2p/16Uiu2HAm6s2pY65dcXi8zM4EfD7oCP4o64C6a8XbxwgLU1q6WAUe,/dns/mainnet-mux-aws.altlayer.network/tcp/31478/p2p/16Uiu2HAmQEAZhJTPSdrJpH2NqZ5X368XPXGq68XxL1r8wQamdbwQ
```

## Mantle

Mantle provides a [snapshot](https://github.com/mantlenetworkio/networks/blob/main/run-node-mainnetv2.md#download-latest-snapshot-from-mantle), which must be used.
It cannot be synced from genesis.

```
NETWORK=mantle
SNAPSHOT=https://current-snapshot-url
OPGETH_DOCKER_TAG=v1.0.2
OPNODE_DOCKER_TAG=v1.0.2
OPGETH_DOCKER_REPO=mantlenetworkio/op-geth
OPNODE_DOCKER_REPO=mantlenetworkio/op-node
SEQUENCER=https://rpc.mantle.xyz
OPNODE_SYNC_MODE=""
DISABLE_TXPOOL_GOSSIP=false
ROLLUP_HALT=""
L1_BEACON=""
CL_EXTRAS=--l2.backup-unsafe-sync-rpc=https://rpc.mantle.xyz --da.indexer-enable --da.indexer-socket=da-indexer-api.mantle.xyz:80 --sequencer.enabled=false --l2.engine-sync=true --l2.skip-sync-start-check=true --p2p.sync.req-resp=true --verifier.l1-confs=3 --p2p.scoring.peers=light --p2p.ban.peers=true
EL_EXTRAS=--syncmode=full --snapshot=false --networkid=5000 --nodiscover --maxpeers=0
GENESIS_URL=""
ROLLUP_URL=https://raw.githubusercontent.com/mantlenetworkio/networks/main/mainnet/rollup.json
OPNODE_P2P_STATIC_PEERS=/dns4/peer0.mantle.xyz/tcp/9003/p2p/16Uiu2HAmKVKzUAns2gLhZAz1PYcbnhY3WpxNxUZYeTN1x29tNBAW,/dns4/peer1.mantle.xyz/tcp/9003/p2p/16Uiu2HAm1AiZtVp8f5C8LvpSTAXC6GtwqAVKnB3VLawWYSEBmcFN,/dns4/peer2.mantle.xyz/tcp/9003/p2p/16Uiu2HAm2UHVKiPXpovs8VbbUQVPr7feBAqBJdFsH1z5XDiLEvHT
```

## Worldchain

```
NETWORK=worldchain-mainnet
SEQUENCER=https://worldchain-mainnet-sequencer.g.alchemy.com
EL_EXTRAS="--override.fjord=1721826000 --override.granite=1727780400 --override.ecotone=0 --override.canyon=0"
CL_EXTRAS="--override.fjord=1721826000 --override.granite=1727780400 --override.ecotone=0 --override.canyon=0 --sequencer.l1-confs=10 --verifier.l1-confs=10 --l1.trustrpc=true"
OPNODE_SYNC_MODE=execution-layer
GENESIS_URL="https://raw.githubusercontent.com/worldcoin/world-id-docs/refs/heads/main/public/code/world-chain/genesis.json"
ROLLUP_URL="https://raw.githubusercontent.com/worldcoin/world-id-docs/refs/heads/main/public/code/world-chain/rollup.json"
OPGETH_P2P_BOOTNODES="enode://dd4e44e87d68dd43bfc16d4fd5d9a6a2cd428986f75ddf15c8a72add0ad425852b9c36b6c5999ab7a37cc64d9bc1b68d549bc088dfa728e84dea7ae617f64e04@107.22.23.212:0?discport=30301,enode://47bd99d0bc393c6ca5569058b2d031067a3df5d05214036a5b88c9b817d52e08d7514d452b1aa623cfb3dd415136dcaf90c962e62d9337ff511fee0e9d1c8b28@18.207.96.148:0?discport=30301"
```

# Version

This is Optimism Docker v3.2.0
