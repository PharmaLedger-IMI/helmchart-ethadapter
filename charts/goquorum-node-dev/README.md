# goquorum-node

![Version: 0.0.1](https://img.shields.io/badge/Version-0.0.1-informational?style=flat-square) ![AppVersion: latest](https://img.shields.io/badge/AppVersion-latest-informational?style=flat-square)

Quorum node for a POA network using IBFT for consensys

## IMPORTANT NOTES

This is a copy of [https://github.com/ConsenSys/quorum-kubernetes/tree/89bddb3d01342f0e336d908de392b62bb8230bc5/dev/helm/charts/goquorum-node](https://github.com/ConsenSys/quorum-kubernetes/tree/89bddb3d01342f0e336d908de392b62bb8230bc5/dev/helm/charts/goquorum-node)

The copy is being used to package the helm chart and publish it in the repo.
See [https://github.com/ConsenSys/quorum-kubernetes/tree/89bddb3d01342f0e336d908de392b62bb8230bc5/dev#usage](https://github.com/ConsenSys/quorum-kubernetes/tree/89bddb3d01342f0e336d908de392b62bb8230bc5/dev#usage) for further details.

```
helm upgrade validator-1 ph-ethadapter/goquorum-node --version=0.0.1 \
    --install \
    --namespace quorum --create-namespace

helm upgrade validator-2 ph-ethadapter/goquorum-node --version=0.0.1 \
    --install \
    --namespace quorum --create-namespace

helm upgrade validator-3 ph-ethadapter/goquorum-node --version=0.0.1 \
    --install \
    --namespace quorum --create-namespace

helm upgrade validator-4 ph-ethadapter/goquorum-node --version=0.0.1 \
    --install \
    --namespace quorum --create-namespace
```

## Maintainers

| Name | Email | Url |
| ---- | ------ | --- |
| Joshua Fernandes | <joshua.fernandes@consensys.net> |  |

## Values

| Key | Type | Default | Description |
|-----|------|---------|-------------|
| affinity | object | `{}` |  |
| image.hooks.pullPolicy | string | `"IfNotPresent"` |  |
| image.hooks.repository | string | `"consensys/quorum-k8s-hooks"` |  |
| image.hooks.tag | string | `"latest"` |  |
| image.quorum.repository | string | `"quorumengineering/quorum"` |  |
| image.quorum.tag | string | `"latest"` |  |
| image.tessera.repository | string | `"quorumengineering/tessera"` |  |
| image.tessera.tag | string | `"latest"` |  |
| node.quorum.account | object | `{}` |  |
| node.quorum.dataPath | string | `"/data/quorum"` |  |
| node.quorum.genesisFilePath | string | `"/etc/genesis/genesis.json"` |  |
| node.quorum.graphql.addr | string | `"0.0.0.0"` |  |
| node.quorum.graphql.corsDomain | string | `"*"` |  |
| node.quorum.graphql.enabled | bool | `true` |  |
| node.quorum.graphql.port | int | `8547` |  |
| node.quorum.graphql.vHosts | string | `"*"` |  |
| node.quorum.keysPath | string | `"/keys"` |  |
| node.quorum.log.verbosity | int | `5` |  |
| node.quorum.metrics.enabled | bool | `true` |  |
| node.quorum.metrics.pprofaddr | string | `"0.0.0.0"` |  |
| node.quorum.metrics.pprofport | int | `9545` |  |
| node.quorum.miner.blockPeriod | int | `5` |  |
| node.quorum.miner.threads | int | `1` |  |
| node.quorum.networkId | int | `10` |  |
| node.quorum.p2p.addr | string | `"0.0.0.0"` |  |
| node.quorum.p2p.enabled | bool | `true` |  |
| node.quorum.p2p.port | int | `30303` |  |
| node.quorum.privacy.pubkeyFile | string | `"/tessera/tm.pub"` |  |
| node.quorum.privacy.pubkeysPath | string | `"/tessera"` |  |
| node.quorum.privacy.url | string | `"http://localhost:9101"` |  |
| node.quorum.replicaCount | int | `1` |  |
| node.quorum.resources.cpuLimit | float | `0.5` |  |
| node.quorum.resources.cpuRequest | float | `0.1` |  |
| node.quorum.resources.memLimit | string | `"2G"` |  |
| node.quorum.resources.memRequest | string | `"1G"` |  |
| node.quorum.rpc.addr | string | `"0.0.0.0"` |  |
| node.quorum.rpc.api | string | `"admin,db,eth,debug,miner,net,shh,txpool,personal,web3,quorum,istanbul"` |  |
| node.quorum.rpc.authenticationEnabled | bool | `false` |  |
| node.quorum.rpc.corsDomain | string | `"*"` |  |
| node.quorum.rpc.enabled | bool | `true` |  |
| node.quorum.rpc.port | int | `8545` |  |
| node.quorum.rpc.vHosts | string | `"*"` |  |
| node.quorum.ws.addr | string | `"0.0.0.0"` |  |
| node.quorum.ws.api | string | `"admin,db,eth,debug,miner,net,shh,txpool,personal,web3,quorum,istanbul"` |  |
| node.quorum.ws.authenticationEnabled | bool | `false` |  |
| node.quorum.ws.enabled | bool | `true` |  |
| node.quorum.ws.origins | string | `"*"` |  |
| node.quorum.ws.port | int | `8546` |  |
| node.tessera.dataPath | string | `"/data/tessera"` |  |
| node.tessera.keysPath | string | `"/keys"` |  |
| node.tessera.password | string | `""` |  |
| node.tessera.port | int | `9000` |  |
| node.tessera.q2tport | int | `9101` |  |
| node.tessera.resources.cpuLimit | float | `0.7` |  |
| node.tessera.resources.cpuRequest | float | `0.5` |  |
| node.tessera.resources.memLimit | string | `"1G"` |  |
| node.tessera.resources.memRequest | string | `"500m"` |  |
| node.tessera.tmkey | string | `""` |  |
| node.tessera.tmpub | string | `""` |  |
| node.tessera.tpport | int | `9080` |  |
| nodeFlags.bootnode | bool | `false` |  |
| nodeFlags.generateKeys | bool | `false` |  |
| nodeFlags.privacy | bool | `false` |  |
| nodeFlags.removeKeysOnDeletion | bool | `false` |  |
| nodeSelector | object | `{}` |  |
| provider | string | `"local"` |  |
| resources | object | `{}` |  |
| storage.pvcSizeLimit | string | `"20Gi"` |  |
| storage.sizeLimit | string | `"20Gi"` |  |
| tolerations | list | `[]` |  |

----------------------------------------------
Autogenerated from chart metadata using [helm-docs v1.8.1](https://github.com/norwoodj/helm-docs/releases/v1.8.1)
