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

## Xlayer
For genesis.json download it from https://okg-pub-hk.oss-cn-hongkong.aliyuncs.com/cdn/chain/xlayer/snapshot/merged.genesis.json.mainnet.tar.gz referenced here https://github.com/okx/xlayer-toolkit/blob/c98ef4d579f641c3bb37d9a8390a6bc8fb572327/scripts/rpc-setup/init.sh#L28C22-L28C130 and place it inside clone dir `private-config`

```properties
COMPOSE_FILE="optimism.yml:ext-network.yml"
NETWORK=xlayer
OPNODE_DOCKERFILE=Dockerfile-debian.binary
OPGETH_DOCKER_REPO=xlayer/op-geth
OPGETH_DOCKER_TAG=0.0.6
OPNODE_DOCKER_REPO=xlayer/op-node
OPNODE_DOCKER_TAG=0.0.9
GENESIS_URL=file:///tmp/private-config/merged.genesis.json
ROLLUP_URL="https://raw.githubusercontent.com/okx/xlayer-toolkit/refs/heads/main/scripts/rpc-setup/config/rollup-mainnet.json"
EL_INIT_EXTRAS="--gcmode=archive --db.engine=pebble"
INIT_STATE_SCHEME=hash
SEQUENCER=https://rpc.xlayer.tech
OPNODE_P2P_STATIC_PEERS=/ip4/47.242.38.0/tcp/9223/p2p/16Uiu2HAmH1AVhKWR29mb5s8Cubgsbh4CH1G86A6yoVtjrLWQgiY3,/ip4/8.210.153.12/tcp/9223/p2p/16Uiu2HAkuerkmQYMZxYiQYfQcPob9H7XHPwS7pd8opPTMEm2nsAp,/ip4/8.210.117.27/tcp/9223/p2p/16Uiu2HAmQEzn2WQj4kmWVrK9aQsfyQcETgXQKjcKGrTPsKcJBv7a
OPNODE_P2P_BOOTNODES=enode://c67d7f63c5483ab8311123d2997bfe6a8aac2b117a40167cf71682f8a3e37d3b86547c786559355c4c05ae0b1a7e7a1b8fde55050b183f96728d62e276467ce1@8.210.177.150:9223,enode://28e3e305b266e01226a7cc979ab692b22507784095157453ee0e34607bb3beac9a5b00f3e3d7d3ac36164612ca25108e6b79f75e3a9ecb54a0b3e7eb3e097d37@8.210.15.172:9223,enode://b5aa43622aad25c619650a0b7f8bb030161dfbfd5664233f92d841a33b404cea3ffffdc5bc8d6667c7dc212242a52f0702825c1e51612047f75c847ab96ef7a6@8.210.69.97:9223
SNAPSHOT=""
EL_EXTRAS="--http.api=web3,debug,eth,txpool,net,engine,miner,admin --ws.api=debug,eth,txtpool,net,engine --db.engine=pebble --gcmode=archive --rollup.enabletxpooladmission --discovery.v5=true --maxpeers=30 --networkid=1952 --syncmode=full --gpo.blocks=20 --gpo.percentile=60 --gpo.maxprice=5000000000000000000 --gpo.ignoreprice=2000000000000000 --gpo.default-l1-coin-price=2000.0 --gpo.l1-coin-id=15756 --gpo.default-l2-coin-price=0.5 --gpo.l2-coin-id=7184 --gpo.type=follower --gpo.factor=0.1 --gpo.update-period=100000000000 --gpo.default=100000000 --gpo.kafka-url=localhost:9092 --gpo.topic=middle_coinPrice_push --gpo.group-id=geth-consumer"
CL_EXTRAS="--log.level=info --sequencer.enabled=false --verifier.l1-confs=1 --rpc.enable-admin=true --conductor.enabled=false --safedb.path=/var/lib/op-node/safedb"
OPNODE_SYNC_MODE=""
OPGETH_P2P_BOOTNODES=""
OPGETH_P2P_TRUSTED_NODES=enode://2104d54a7fbd58a408590035a3628f1e162833c901400d490ccc94de416baf13639ce2dad388b7a5fd43c535468c106b660d42d94451e39b08912005aa4e4195@8.210.181.50:30303
```

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
EIGENDA_DOCKER_TAG=v1.6.4
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

## opBNB
```properties
NETWORK=opBNBMainnet
OPNODE_DOCKER_TAG=v0.5.3-hotfix
OPGETH_DOCKER_TAG=v0.5.7
OPGETH_DOCKER_REPO=ghcr.io/bnb-chain/op-geth
OPNODE_DOCKER_REPO=ghcr.io/bnb-chain/op-node
SNAPSHOT=https://pub-2ea2209b4ee74f4398c5ac50c3b2efeb.r2.dev/geth-mainnet-pbss-20250516.tar.gz
SEQUENCER=https://opbnb-mainnet-rpc.bnbchain.org
OPGETH_P2P_BOOTNODES=enr:-KO4QHs5qh_kPFcjMgqkuN9dbxXT4C5Cjad4SAheaUxveCbJQ3XdeMMDHeHilHyqisyYQAByfdhzyKAdUp2SvyzWeBqGAYvRDf80g2V0aMfGhHFtSjqAgmlkgnY0gmlwhDaykUmJc2VjcDI1NmsxoQJUevTL3hJwj21IT2GC6VaNqVQEsJFPtNtO-ld5QTNCfIRzbmFwwIN0Y3CCdl-DdWRwgnZf,enr:-KO4QKIByq-YMjs6IL2YCNZEmlo3dKWNOy4B6sdqE3gjOrXeKdNbwZZGK_JzT1epqCFs3mujjg2vO1lrZLzLy4Rl7PyGAYvRA8bEg2V0aMfGhHFtSjqAgmlkgnY0gmlwhDbjSM6Jc2VjcDI1NmsxoQNQhJ5pqCPnTbK92gEc2F98y-u1OgZVAI1Msx-UiHezY4RzbmFwwIN0Y3CCdl-DdWRwgnZf
OPNODE_P2P_BOOTNODES=enr:-J24QA9sgVxbZ0KoJ7-1gx_szfc7Oexzz7xL2iHS7VMHGj2QQaLc_IQZmFthywENgJWXbApj7tw7BiouKDOZD4noWEWGAYppffmvgmlkgnY0gmlwhDbjSM6Hb3BzdGFja4PMAQCJc2VjcDI1NmsxoQKetGQX7sXd4u8hZr6uayTZgHRDvGm36YaryqZkgnidS4N0Y3CCIyuDdWRwgiMs,enr:-J24QPSZMaGw3NhO6Ll25cawknKcOFLPjUnpy72HCkwqaHBKaaR9ylr-ejx20INZ69BLLj334aEqjNHKJeWhiAdVcn-GAYv28FmZgmlkgnY0gmlwhDTDWQOHb3BzdGFja4PMAQCJc2VjcDI1NmsxoQJ-_5GZKjs7jaB4TILdgC8EwnwyL3Qip89wmjnyjvDDwoN0Y3CCIyuDdWRwgiMs
EL_EXTRAS=--syncmode=full --db.engine=pebble
CL_EXTRAS=--l1.trustrpc
OPNODE_SYNC_MODE=execution-layer
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

## Hemi

`hemi-min.yml` is required in `COMPOSE_FILE`. Additional entries such as `op-shared.yml` can of course be used.

```properties
COMPOSE_FILE=optimism.yml:hemi-min.yml
NETWORK=hemi-mainnet
SEQUENCER=""
CL_EXTRAS=--sequencer.enabled=false --p2p.ban.peers=false --p2p.ban.duration=1s --p2p.ban.threshold=-10000000000 --override.ecotone=1725868497 --override.canyon=1725868497 --override.delta=1725868497 --override.pectrablobschedule=1751554801 --override.isthmus=1751554801 --override.holocene=1751554801 --override.granite=1751554801 --override.fjord=1751554801
EL_EXTRAS=--syncmode=snap --gcmode=archive --networkid=43111 --override.ecotone=1725868497 --override.canyon=1725868497 --override.cancun=1725868497 --override.hvm0=1739286001 --override.isthmus=1751554801 --override.holocene=1751554801 --override.granite=1751554801 --override.fjord=1751554801 --tbc.leveldbhome=/var/lib/tbc/data --hvm.headerdatadir=/var/lib/tbc/headers --tbc.network=mainnet --hvm.genesisheader=0000003efaaa2ba65de684c512bb67ef115298d1d16bcb49b16c02000000000000000000ed31a56788c4488afc4ee69e0791ad6aeeb9ea05f069e0fdde6159068765ad3f4128a96726770217e7f41c86 --hvm.genesisheight=883092 --http.api=web3,eth,txpool,net --ws.api=eth,txpool,net --maxpeers=100 --blobpool.datacap 10737418240 --miner.gasprice 10
OPNODE_SYNC_MODE=execution-layer
DISABLE_TXPOOL_GOSSIP=false
ROLLUP_HALT=""
GENESIS_URL=https://raw.githubusercontent.com/hemilabs/heminetwork/refs/heads/main/localnode/mainnet-genesis.json
INIT_STATE_SCHEME=hash
ROLLUP_URL=https://raw.githubusercontent.com/hemilabs/heminetwork/refs/heads/main/localnode/mainnet-rollup.json
OPNODE_P2P_BOOTNODES=enr:-J64QACnJ0giPmPXowNCHP-FDleMMbDqYg5nuLABYfJeYbP9OA6_fZtvCsTbAwvlPD8_C6ZSXEk1-XPabDBwD8UTyNCGAZMxdy4tgmlkgnY0gmlwhCINopiHb3BzdGFja4Tn0AIAiXNlY3AyNTZrMaED22EOmUryrNnFOwq6Ve1Hpw5CMFz_TnhIkVS4Sq8JhkmDdGNwgiMrg3VkcIKjLg,enr:-J64QA20VNMfLMtbSuHYmQH2I-xaqT4-9g7lqO-VHr0fFvtSB7QybJ_7W5fuEjLAa6kh82fGLjRUdZE0hW0pfVBcxP6GAZMxdwfngmlkgnY0gmlwhCJaFfaHb3BzdGFja4Tn0AIAiXNlY3AyNTZrMaEDjt3C-gv87B5rWa5M52WUFGy16mjQvFsC7OgPkqu-rn-DdGNwgiMrg3VkcIKRXQ,enr:-J64QLQyh3lXjQLzfCbfNw0DUb4A0OEcTLmVGexMbK-2jjCtHOIlRnDqLuedQ0orNHt7zmsILELYi4ozg-0bQzc34F-GAZMxdxNogmlkgnY0gmlwhCINq4uHb3BzdGFja4Tn0AIAiXNlY3AyNTZrMaED1NV9w0EmnMXBNRnDWj6kdqzE6_4HigHopeu3ewQTwouDdGNwgiMrg3VkcIK1Iw,enr:-J64QNPfOEViWkN7U_ul5Zhw_mc5_Hta92eUufrgu6oTqSMzRsqCje-P0vPrOQ9XjVIk4VP7mmFVP6qoTrtkIwvwUV2GAZMxdv4zgmlkgnY0gmlwhCJb2HmHb3BzdGFja4Tn0AIAiXNlY3AyNTZrMaEDYAidV8rzABKrKAL9jwP1aoi3wj-GtuML4FKtUDOgzCGDdGNwgiMrg3VkcILijg,enr:-J64QFalFr9Y4r9v8Svh7XFwerJeLTRnfTixfCy_NZw3OTMVZL_dSAvcZ6JIeK0JAZf6-PU3YknV9m9Jd5V5WlnqHKWGAZMxdxT4gmlkgnY0gmlwhCKNlBOHb3BzdGFja4Tn0AIAiXNlY3AyNTZrMaECI1jqAzkQ0JRkwL-UBP2TBUfUdLyTaqAXtey82CTysdCDdGNwgiMrg3VkcILOyg
OPNODE_P2P_STATIC_PEERS=/ip4/34.90.21.246/tcp/9003/p2p/16Uiu2HAmNGgNTgiFBAqH58aCT3iXWMnetYMtQgH21Ydjq2R7QRbt,/ip4/34.13.162.152/tcp/9003/p2p/16Uiu2HAm33YRmCya94zRXddxaWj25QAXW5MhuJkaEvfMLXkB4GCK,/ip4/34.13.171.139/tcp/9003/p2p/16Uiu2HAm5d71wTbQPkBA3VW9suge2afCKtrGdk7UapRHR4va8jTY,/ip4/34.91.216.121/tcp/9003/p2p/16Uiu2HAmK7s7F1ALmtXKH3LxeEENstqw8jiDzUtifasS4LkUKGVE,/ip4/34.141.148.19/tcp/9003/p2p/16Uiu2HAkwoetK83q3WNRQ4t4eV8B3DosnwcFqd9VHxz24ZZzzEgo
OPGETH_P2P_BOOTNODES=enode://e7970a29d89f8b158371a8d4aca909ee8c1c759e711547b797a6a6f01513c1e7c85121dd2600397ca20cebf3cea21025001be7c0f577b496caf32ea0433a1cfd@34.90.21.246:30303,enode://70877d3aa6c4ccc09d960c269846215d5dcc8bf47013ac532c1ccc3d9cfe61434c96b9d6cad88a96c3f91187fb00214d903a6be6d8e93140ac4a3c099684ce34@34.13.162.152:30303,enode://27f75e68a8c14cae2f4e12f060477c150767e98149e16a448baddc25d800c008edf8b1fefd13b206c27e5473ac9234ba1958a8267fe5272e9de3819ac080bf22@34.13.171.139:30303,enode://588ffb65f841aede8d8f69a3175f9cfed1b79d20d40a7feb8a70e574b5610fb4049bf02f3170f1ae25bff806b2c823653b28af711e1962ea3f45d99d58608191@34.91.216.121:30303,enode://ba86a76186268948bc34b7fa1c2f08c24ed60cda61346cf1a1cca278b0ef1de49e567039952e06e4887a0252974401a6d6729bfc12945c6d8c65eacbf3b11ca7@34.141.148.19:30303
OPGETH_P2P_TRUSTED_NODES=["enode://e7970a29d89f8b158371a8d4aca909ee8c1c759e711547b797a6a6f01513c1e7c85121dd2600397ca20cebf3cea21025001be7c0f577b496caf32ea0433a1cfd@34.90.21.246:30303","enode://70877d3aa6c4ccc09d960c269846215d5dcc8bf47013ac532c1ccc3d9cfe61434c96b9d6cad88a96c3f91187fb00214d903a6be6d8e93140ac4a3c099684ce34@34.13.162.152:30303","enode://27f75e68a8c14cae2f4e12f060477c150767e98149e16a448baddc25d800c008edf8b1fefd13b206c27e5473ac9234ba1958a8267fe5272e9de3819ac080bf22@34.13.171.139:30303","enode://588ffb65f841aede8d8f69a3175f9cfed1b79d20d40a7feb8a70e574b5610fb4049bf02f3170f1ae25bff806b2c823653b28af711e1962ea3f45d99d58608191@34.91.216.121:30303","enode://ba86a76186268948bc34b7fa1c2f08c24ed60cda61346cf1a1cca278b0ef1de49e567039952e06e4887a0252974401a6d6729bfc12945c6d8c65eacbf3b11ca7@34.141.148.19:30303"]
OPNODE_DOCKER_TAG=ea9fe7b@sha256:7110e3c4c61e495ea0a6621d7ec211ceb7e948e25c648b05bd51fcc557ad06bc
OPNODE_DOCKER_REPO=ghcr.io/hemilabs/op-node
OPGETH_DOCKER_TAG=e79d992@sha256:dbe292e013345a8a41c9dc8ee09088853410b17c06ef779258d251f55356c501
OPGETH_DOCKER_REPO=ghcr.io/hemilabs/op-geth
HEMI_BSSD_DOCKER_TAG=1.6.3
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

## Base

```properties
NETWORK=base-mainnet
SEQUENCER=""
```

## Zora

```properties
NETWORK=zora-mainnet
SEQUENCER=""
```

## Metal

```properties
NETWORK=metal-mainnet
SEQUENCER=""
```

## Mint

```properties
NETWORK=mint-mainnet
SEQUENCER=""
```

## Lisk

```properties
NETWORK=lisk-mainnet
SEQUENCER=""
```

## Superseed

```properties
NETWORK=superseed-mainnet
SNAPSHOT=https://storage.googleapis.com/conduit-networks-snapshots/superseed-mainnet-0/latest.tar
CL_EXTRAS=--override.granite=1726185601 --override.holocene=1736445601 --override.isthmus=1746806401 --p2p.sync.onlyreqtostatic=true
EL_EXTRAS=--nodiscover --maxpeers=100 --override.granite=1726185601 --override.holocene=1736445601 --override.isthmus=1746806401
INIT_STATE_SCHEME=hash
OPNODE_DOCKER_TAG=v1.13.2
OPGETH_DOCKER_TAG=v1.101503.4
SEQUENCER=https://mainnet.superseed.xyz
OPNODE_SYNC_MODE=consensus-layer
GENESIS_URL=https://raw.githubusercontent.com/superseed-xyz/node/refs/heads/main/config/superseed-mainnet/genesis.json
ROLLUP_URL=https://raw.githubusercontent.com/superseed-xyz/node/refs/heads/main/config/superseed-mainnet/rollup.json
DISABLE_TXPOOL_GOSSIP=false
OPGETH_P2P_BOTNODES="enode://3e905f39a5c084367bbe172453cf6d81b28a49f57064b56b0eb76af75d6eafe3d578605f56c4353328194245453083e1c26e339497f732461d2187d0c4a4474e@35.203.166.40:9222?discport=30301,enode://d25ce99435982b04d60c4b41ba256b84b888626db7bee45a9419382300fbe907359ae5ef250346785bff8d3b9d07cd3e017a27e2ee3cfda3bcbb0ba762ac9674@bootnode.conduit.xyz:0?discport=30301,enode://2d4e7e9d48f4dd4efe9342706dd1b0024681bd4c3300d021f86fc75eab7865d4e0cbec6fbc883f011cfd6a57423e7e2f6e104baad2b744c3cafaec6bc7dc92c1@34.65.43.171:0?discport=30305,enode://9d7a3efefe442351217e73b3a593bcb8efffb55b4807699972145324eab5e6b382152f8d24f6301baebbfb5ecd4127bd3faab2842c04cd432bdf50ba092f6645@34.65.109.126:0?discport=30305"
OPNODE_P2P_STATIC_PEERS="/ip4/35.203.166.40/tcp/9222/p2p/16Uiu2HAkydtwWKfTJVk91zmc4JnBzathYyqLSDtw3RCFW1mwkPMk"
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
EL_EXTRAS="--networkid=252 --maxpeers=50 --syncmode=snap --override.canyon=0 --override.ecotone=1717009201 --override.fjord=1733947201 --override.granite=1738958401 --override.isthmus=1755716401"
OPNODE_DOCKER_REPO=ghcr.io/fraxfinance/fraxtal-op-node
OPGETH_DOCKER_REPO=ghcr.io/fraxfinance/fraxtal-op-geth
OPNODE_DOCKER_TAG=v1.13.5-frax-1.2.0
OPGETH_DOCKER_TAG=v1.101511.1-frax-1.3.0
NETWORK=fraxtal-mainnet
SEQUENCER="https://rpc.frax.com"
OPNODE_SYNC_MODE=execution-layer
GENESIS_URL=https://raw.githubusercontent.com/FraxFinance/fraxtal-node/refs/heads/master/mainnet/genesis.json
ROLLUP_URL=https://raw.githubusercontent.com/FraxFinance/fraxtal-node/refs/heads/master/mainnet/rollup.json
OPNODE_P2P_BOOTNODES="enr:-J24QPGxmNmQ6Gsofjwnaaqt-RvC-2te44hHSU_wFGvCBpdnGnAuW0hKBCwzarXEmLN0TfwilwX3xS8xjEd9sQRqKXqGAY1ok0P3gmlkgnY0gmlwhDa-pcmHb3BzdGFja4P8AQCJc2VjcDI1NmsxoQJA0echCE64KVt7m1lHfRF9_QgYxqIOSoPZ1UHcEArDu4N0Y3CCJAaDdWRwgiQG,enr:-J24QHPYu7uUXH4LCJ_pjHMD3fYhluZEgFRlewqOFFcja7ACaTDp4zG4GZBJdTPmLjsqskhTQa5ldKiVu4ypZYMzR_uGAY1ok_ABgmlkgnY0gmlwhCLvv1KHb3BzdGFja4P8AQCJc2VjcDI1NmsxoQOEemNzZL5buGmwlN2naXLtz4nauCqBFeFxdmi4RL4rDIN0Y3CCJAaDdWRwgiQG,enr:-J24QBujtfGNIiE6GJrCgXEKJMs1F11wd4Y8Uvx7ZFn3Z1tyR0erNcpiW5EYIQEKQX0kL9PLJUDHWZFiaHWOTBvFg5aGAY1ok5p8gmlkgnY0gmlwhDbD-tqHb3BzdGFja4P8AQCJc2VjcDI1NmsxoQLunzKLYJLvy6cWWkLgSSdLlILgSohrV8RT3tlKGwHBi4N0Y3CCJAaDdWRwgiQG"
OPGETH_P2P_BOOTNODES="enr:-J24QI8QR7VIgvQFuvLl09b9ocugoQ1WkS_AOMWKFgNX48-4P1hjgDKGeMFXZmKtfjYA2aEehxKT066riaktnxhh92OGAY5Sw_QsgmlkgnY0gmlwhCztZu2Hb3BzdGFja4P8AQCJc2VjcDI1NmsxoQM2KM0mkdH97Ze8AqwxLeqc934PKj8-xoKsyP6mAptWwIN0Y3CCdl2DdWRwgnZd,enr:-J24QGD1J-g2EPY9b7XiuwLhIoGocVp2qx2gWSfDI_CdftiPSHlgi7G6LtzkQlDskuSvRj4OXTg3vXLISubphXNNhqyGAY5Sw8GxgmlkgnY0gmlwhCzW_iGHb3BzdGFja4P8AQCJc2VjcDI1NmsxoQPvMYlJHJUsEyciuJCTkKHLE2ogZ6cs2xuPI28CGq0CTIN0Y3CCdl2DdWRwgnZd,enr:-J24QCA5I3xroUXt7Ge_Kf04VCRBnI-GbZeyBxOkkpIDGGLrVsonrbngQG1hAEnufRb1TgS6sNFCGtaZ2ZpRx7AgciGGAY5SxEy0gmlkgnY0gmlwhCLzRQyHb3BzdGFja4P8AQCJc2VjcDI1NmsxoQOaHzrtPQWYcwAcFJWFrbGlbNUsBC0VEhCcH02RbgEIwIN0Y3CCdl2DdWRwgnZd"
```

# Version

This is Optimism Docker v3.3.1
