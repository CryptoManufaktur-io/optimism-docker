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

# For networks that use `genesis.json` and `rollup.json` files

The repo supports both local and remote files for `genesis.json` and `rollup.json`. Using `https://` or `file://` it can detect to download the file or use a locally mounted file.

To use a locally mounted file, add the files to `private-config` folder and then set the path as follows.

```properties
GENESIS_URL=file:///tmp/private-config/genesis-l2.json
ROLLUP_URL=file:///tmp/private-config/rollup.json
```

# Other OP Stack chains

Optimism Docker supports OP Stack chains that are not part of the Superchain Registry, or maybe are but still
need additional parameters.

You'll want to set `NETWORK` to something unique (it cannot be empty), then set `GENESIS_URL`, `ROLLUP_URL`,
`SEQUENCER`, as well as `EL_EXTRAS`, `CL_EXTRAS`, `SYNC_MODE`, `OPGETH_P2P_BOOTNODES` and `OPNODE_P2P_BOOTNODES` as needed.

Some example values by chain are below

## Celo

Celo requires eigenda-proxy so make sure to add `eigenda.yml` in `COMPOSE_FILE` as below. Then you set the value using arguments as seen in CL_EXTRAS `--altda.da-server=http://eigenda-proxy:4242`

```properties
COMPOSE_FILE="optimism.yml:eigenda.yml"
CL_EXTRAS=--l1.trustrpc --altda.enabled=true --altda.da-service=true --altda.verify-on-read=false --altda.da-server=http://eigenda-proxy:4242
EL_EXTRAS=--syncmode=snap --gcmode=full --snapshot=true --history.transactions=0
OPNODE_DOCKER_REPO=us-west1-docker.pkg.dev/devopsre/celo-blockchain-public/op-node
OPGETH_DOCKER_REPO=us-west1-docker.pkg.dev/devopsre/celo-blockchain-public/op-geth
OPNODE_DOCKER_TAG=celo-v2.0.0
OPGETH_DOCKER_TAG=celo-v2.0.0

EIGENDA_DOCKER_REPO=ghcr.io/layr-labs/eigenda-proxy
EIGENDA_VERSION=v1.6.4
PORT_EIGENDA_PROXY=4242
EIGENDA_LOCAL_DISPERSER_RPC=disperser.eigenda.xyz:443
EIGENDA_LOCAL_SVC_MANAGER_ADDR="0x870679e138bcdf293b7ff14dd44b70fc97e12fc0"

NETWORK=celo-mainnet
SEQUENCER="https://cel2-sequencer.celo.org"
OPNODE_SYNC_MODE=execution-layer
GENESIS_URL=https://raw.githubusercontent.com/celo-org/celo-l2-node-docker-compose/refs/heads/main/envs/mainnet/config/genesis.json
ROLLUP_URL=https://raw.githubusercontent.com/celo-org/celo-l2-node-docker-compose/refs/heads/main/envs/mainnet/config/rollup.json
OPNODE_P2P_BOOTNODES="enr:-J64QJipvmFhMq6DVh6RR4HvIiiBtyy1NUg_QlnAAbf18SMqCxCPZtLgUiWED5p0HRVPv69Wth4YPsvdKXSUyh57mWuGAZXRp6HjgmlkgnY0gmlwhCJTtG-Hb3BzdGFja4TsyQIAiXNlY3AyNTZrMaECKPT8t_OMGwEgh_eu8l3LChJXzPHNxMqohYTcJUFhKQaDdGNwgiQGg3VkcIIkBg,enr:-J64QCxBGS49IQbkbwsUuVWt9CkMctMCRe0b-4dqRsLr4QJ1S52urWPUk2uhBU5uerRGpxWTZZW5FtJC-9gSBHN3cSiGAZXRp4rbgmlkgnY0gmlwhCKph0CHb3BzdGFja4TsyQIAiXNlY3AyNTZrMaECqQd8PgMCBpVMXH8izBajLLUBMRKqiYXjV1-t2niEpQiDdGNwgiQGg3VkcIIkBg,enr:-J64QLG71bmmljNbLFx3qim6zXohKA3jbK_4C4d1cwixI-7VMoBIlnM6kWZVvvdWcbjTQ6QXB1LAO39eZWC4Heztj1-GAZXRpzUGgmlkgnY0gmlwhCKpySSHb3BzdGFja4TsyQIAiXNlY3AyNTZrMaEDApsAenpWrLqo6lDsYs2ieUhL84Q_rhZG9pBWb3hKylCDdGNwgiQGg3VkcIIkBg,enr:-J64QKFU-u1x1gt3WmNP88EDUMQ316ymbzdGy83QjkBDqVSsJBn6-nipuqYQDeHYoLBLVJUMdyAiwxVbbDm14qQSf5qGAZXRppmIgmlkgnY0gmlwhCJTfzOHb3BzdGFja4TsyQIAiXNlY3AyNTZrMaEC88lrc6V3LF77SNWjO_GT5YCA2Ca6fwPp1b3vIMBjSk-DdGNwgiQGg3VkcIIkBg,enr:-J64QIXTVl0Opbdn20TSrkzpIZ4xQ54bERRlTmSeZ05dFLdlSbuRY7yn5tJeTPzsSldTw5V5E0qjEQcsfr20vMjTUDyGAZXRpiWygmlkgnY0gmlwhCPjrx6Hb3BzdGFja4TsyQIAiXNlY3AyNTZrMaED2qWtZdFrywlnz0eNnyBUS_G23mF2NORS3_e5RyefQfSDdGNwgiQGg3VkcIIkBg,enr:-J64QFAsbeR4xRSyVyQOk7bILUCoMjI2EnbZvo4UAK3842HMYw41-UZXdnQJH8lwvzWn7qsY3Vu73NuxzxWKn4XB5wiGAZXRpYPAgmlkgnY0gmlwhCJSxmKHb3BzdGFja4TsyQIAiXNlY3AyNTZrMaEDx51ZbXcmg4flmWldI-lBwUwiB0UFLqZkKnHvffMaE4eDdGNwgiQGg3VkcIIkBg,enr:-J64QFQSrL3mfG-i64T-5DgVE5V9dGKC5A0JrEvD6CRpZvuLK3feg4bPaqFWfqXyNN_6IgY2z1Jkr4Mf2Zx-GdWlWquGAZXQkMdSgmlkgnY0gmlwhCImtd-Hb3BzdGFja4TsyQIAiXNlY3AyNTZrMaEDQVEzYHXdCOtsdb_WOFXopL1v0Pka5KgbFJMPJnHhau6DdGNwgiQGg3VkcIIkBg,enr:-J64QAp3g1m-5uX-_mBXWyo6ZQqAlnRcAt11Xwy0-ZzqaSrDSlg4adyOz6v9flzLgxYkVvXI50nJGs8GjLgT5bwDLtyGAZXQrD69gmlkgnY0gmlwhCJMJgaHb3BzdGFja4TsyQIAiXNlY3AyNTZrMaECq5mdt1EmXHFLFxNE3hly7XQ0gWLeRloERPVuULjP0EiDdGNwgiQGg3VkcIIkBg,enr:-J64QFCZs1ePThNEsRxIIzbfDxYfap1nEyuPPpSUeeWOoPFWOp0zSEPwLEtXhG1eH-ipsB5CgtaVzcXOyT9hKeAeVVaGAZXQkaZ3gmlkgnY0gmlwhCO7ajaHb3BzdGFja4TsyQIAiXNlY3AyNTZrMaEDnYbZL7OKQpMwVG_hrvziZOH1XF1AJJtjFT5990QAX6ODdGNwgiQGg3VkcIIkBg,enr:-J64QJ9LY8m9AjNgujuVT0juX8T6PHKojZEIqd-7_vhBasfiT2xUUJoUfWga_xVJGFECFcN6hPKB4TjihmYFxHXelwOGAZXQkclrgmlkgnY0gmlwhCJMELeHb3BzdGFja4TsyQIAiXNlY3AyNTZrMaEDyCwx8h3Vu7jcNWhv9npDUzgrQBfJ7HZgo4PMtbjjsEyDdGNwgiQGg3VkcIIkBg,enr:-J64QGJFPZzLj2GLFgB4JhTde7rXChMNFERNbzrwYYTG7CY2SCSggFrU3VXczzWBvOoJWdbOMOzPuCI2klknGjruUxeGAZXQkf1LgmlkgnY0gmlwhGjHJzuHb3BzdGFja4TsyQIAiXNlY3AyNTZrMaEDO61fV62N5lQfAuNtgGuH5-nKbVM8lW6JpWswVK6F1giDdGNwgiQGg3VkcIIkBg,enr:-J64QEXleDl25w0qEG__wmDgwnzB0F5zapu00D_jM4qkCbA3WIcLC8rXPm8dcrKdZNBuNXJOtNE6c2_ZDkuQMvIuhjCGAZXQwDjFgmlkgnY0gmlwhCKMdU-Hb3BzdGFja4TsyQIAiXNlY3AyNTZrMaECHezzuLmg0LgzLRUhjzvwzrlgaw7-GPNSxR7_wUu_H0-DdGNwgiQGg3VkcIIkBg"
OPGETH_P2P_BOOTNODES="enode://28f4fcb7f38c1b012087f7aef25dcb0a1257ccf1cdc4caa88584dc25416129069b514908c8cead5d0105cb0041dd65cd4ee185ae0d379a586fb07b1447e9de38@34.169.39.223:30303,enode://a9077c3e030206954c5c7f22cc16a32cb5013112aa8985e3575fadda7884a508384e1e63c077b7d9fcb4a15c716465d8585567f047c564ada2e823145591e444@34.169.212.31:30303,enode://029b007a7a56acbaa8ea50ec62cda279484bf3843fae1646f690566f784aca50e7d732a9a0530f0541e5ed82ba9bf2a4e21b9021559c5b8b527b91c9c7a38579@34.82.139.199:30303,enode://f3c96b73a5772c5efb48d5a33bf193e58080d826ba7f03e9d5bdef20c0634a4f83475add92ab6313b7a24aa4f729689efb36f5093e5d527bb25e823f8a377224@34.82.84.247:30303,enode://daa5ad65d16bcb0967cf478d9f20544bf1b6de617634e452dff7b947279f41f408b548261d62483f2034d237f61cbcf92a83fc992dbae884156f28ce68533205@34.168.45.168:30303,enode://c79d596d77268387e599695d23e941c14c220745052ea6642a71ef7df31a13874cb7f2ce2ecf5a8a458cfc9b5d9219ce3e8bc6e5c279656177579605a5533c4f@35.247.32.229:30303,enode://4151336075dd08eb6c75bfd63855e8a4bd6fd0f91ae4a81b14930f2671e16aee55495c139380c16e1094a49691875e69e40a3a5e2b4960c7859e7eb5745f9387@35.205.149.224:30303,enode://ab999db751265c714b171344de1972ed74348162de465a0444f56e50b8cfd048725b213ba1fe48c15e3dfb0638e685ea9a21b8447a54eb2962c6768f43018e5c@34.79.3.199:30303,enode://9d86d92fb38a429330546fe1aefce264e1f55c5d40249b63153e7df744005fa3c1e2da295e307041fd30ab1c618715f362c932c28715bc20bed7ae4fc76dea81@34.77.144.164:30303,enode://c82c31f21dd5bbb8dc35686ff67a4353382b4017c9ec7660a383ccb5b8e3b04c6d7aefe71203e550382f6f892795728570f8190afd885efcb7b78fa398608699@34.76.202.74:30303,enode://3bad5f57ad8de6541f02e36d806b87e7e9ca6d533c956e89a56b3054ae85d608784f2cd948dc685f7d6bbd5a2f6dd1a23cc03e529ea370dd72d880864a2af6a3@104.199.93.87:30303,enode://1decf3b8b9a0d0b8332d15218f3bf0ceb9606b0efe18f352c51effc14bbf1f4f3f46711e1d460230cb361302ceaad2be48b5b187ad946e50d729b34e463268d2@35.240.26.148:30303"
```

## B^2

```properties
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

```properties
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

```properties
NETWORK=bob-mainnet
SEQUENCER=https://rpc.gobob.xyz
OPNODE_SYNC_MODE=execution-layer
```

## Unichain

```properties
NETWORK=unichain-mainnet
SEQUENCER=https://mainnet-sequencer.unichain.org
OPNODE_SYNC_MODE=execution-layer
```


## Ink

Ink provides a [snapshot](https://storage.googleapis.com/raas-op-geth-snapshots-e2025/datadir-archive/latest), which
is optional. It can be synced from Genesis, but is faster from snapshot.

Ink's snapshot link gives you a path, which should be combined with
`https://storage.googleapis.com/raas-op-geth-snapshots-e2025/datadir-archive/` to get a full URL.

```properties
NETWORK=ink-mainnet
SEQUENCER=https://rpc-gel.inkonchain.com
OPNODE_SYNC_MODE=execution-layer
```

## Hashkey

```properties
NETWORK=hashkeychain-mainnet
SEQUENCER=https://mainnet.hsk.xyz
OPNODE_SYNC_MODE=execution-layer
```

## Mantle

Mantle provides a [snapshot](https://github.com/mantlenetworkio/networks/blob/main/run-node-mainnetv2.md#download-latest-snapshot-from-mantle), which must be used.
It cannot be synced from genesis.

```properties
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

## Soneium

```properties
NETWORK=soneium-mainnet
SEQUENCER=""
```

## Worldchain

```properties
NETWORK=worldchain-mainnet
SEQUENCER=https://worldchain-mainnet-sequencer.g.alchemy.com
OPNODE_SYNC_MODE=execution-layer
INIT_STATE_SCHEME=hash
```

## Fraxtal

```properties
CL_EXTRAS="--da.rpc=https://da-rpc.mainnet.frax.com"
EL_EXTRAS="--networkid=252 --maxpeers=50 --syncmode=snap --override.canyon=0 --override.ecotone=1717009201 --override.fjord=1733947201 --override.granite=1738958401"
OPNODE_DOCKER_REPO=ghcr.io/fraxfinance/fraxtal-op-node
OPGETH_DOCKER_REPO=ghcr.io/fraxfinance/fraxtal-op-geth
OPNODE_DOCKER_TAG=v1.9.5-frax-1.1.0
OPGETH_DOCKER_TAG=v1.101411.6-frax-1.0.0
NETWORK=fraxtal-mainnet
SEQUENCER="https://rpc.frax.com"
OPNODE_SYNC_MODE=execution-layer
GENESIS_URL=https://raw.githubusercontent.com/FraxFinance/fraxtal-node/refs/heads/master/mainnet/genesis.json
ROLLUP_URL=https://raw.githubusercontent.com/FraxFinance/fraxtal-node/refs/heads/master/mainnet/rollup.json
OPNODE_P2P_BOOTNODES="enr:-J24QPGxmNmQ6Gsofjwnaaqt-RvC-2te44hHSU_wFGvCBpdnGnAuW0hKBCwzarXEmLN0TfwilwX3xS8xjEd9sQRqKXqGAY1ok0P3gmlkgnY0gmlwhDa-pcmHb3BzdGFja4P8AQCJc2VjcDI1NmsxoQJA0echCE64KVt7m1lHfRF9_QgYxqIOSoPZ1UHcEArDu4N0Y3CCJAaDdWRwgiQG,enr:-J24QHPYu7uUXH4LCJ_pjHMD3fYhluZEgFRlewqOFFcja7ACaTDp4zG4GZBJdTPmLjsqskhTQa5ldKiVu4ypZYMzR_uGAY1ok_ABgmlkgnY0gmlwhCLvv1KHb3BzdGFja4P8AQCJc2VjcDI1NmsxoQOEemNzZL5buGmwlN2naXLtz4nauCqBFeFxdmi4RL4rDIN0Y3CCJAaDdWRwgiQG,enr:-J24QBujtfGNIiE6GJrCgXEKJMs1F11wd4Y8Uvx7ZFn3Z1tyR0erNcpiW5EYIQEKQX0kL9PLJUDHWZFiaHWOTBvFg5aGAY1ok5p8gmlkgnY0gmlwhDbD-tqHb3BzdGFja4P8AQCJc2VjcDI1NmsxoQLunzKLYJLvy6cWWkLgSSdLlILgSohrV8RT3tlKGwHBi4N0Y3CCJAaDdWRwgiQG"
OPGETH_P2P_BOOTNODES="enr:-J24QI8QR7VIgvQFuvLl09b9ocugoQ1WkS_AOMWKFgNX48-4P1hjgDKGeMFXZmKtfjYA2aEehxKT066riaktnxhh92OGAY5Sw_QsgmlkgnY0gmlwhCztZu2Hb3BzdGFja4P8AQCJc2VjcDI1NmsxoQM2KM0mkdH97Ze8AqwxLeqc934PKj8-xoKsyP6mAptWwIN0Y3CCdl2DdWRwgnZd,enr:-J24QGD1J-g2EPY9b7XiuwLhIoGocVp2qx2gWSfDI_CdftiPSHlgi7G6LtzkQlDskuSvRj4OXTg3vXLISubphXNNhqyGAY5Sw8GxgmlkgnY0gmlwhCzW_iGHb3BzdGFja4P8AQCJc2VjcDI1NmsxoQPvMYlJHJUsEyciuJCTkKHLE2ogZ6cs2xuPI28CGq0CTIN0Y3CCdl2DdWRwgnZd,enr:-J24QCA5I3xroUXt7Ge_Kf04VCRBnI-GbZeyBxOkkpIDGGLrVsonrbngQG1hAEnufRb1TgS6sNFCGtaZ2ZpRx7AgciGGAY5SxEy0gmlkgnY0gmlwhCLzRQyHb3BzdGFja4P8AQCJc2VjcDI1NmsxoQOaHzrtPQWYcwAcFJWFrbGlbNUsBC0VEhCcH02RbgEIwIN0Y3CCdl2DdWRwgnZd"
```

# Version

This is Optimism Docker v3.2.0
