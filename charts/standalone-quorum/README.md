# standalone-quorum

![Version: 0.3.0](https://img.shields.io/badge/Version-0.3.0-informational?style=flat-square) ![Type: application](https://img.shields.io/badge/Type-application-informational?style=flat-square) ![AppVersion: 21.10.2](https://img.shields.io/badge/AppVersion-21.10.2-informational?style=flat-square)

A Helm chart for a standalone Quorum network adapted from https://github.com/ConsenSys/quorum-kubernetes/tree/master/playground/kubectl/quorum-go/ibft

## Requirements

- [helm 3](https://helm.sh/docs/intro/install/)

## IMPORTANT NOTES

This is an adapted copy of [https://github.com/ConsenSys/quorum-kubernetes/tree/89bddb3d01342f0e336d908de392b62bb8230bc5/playground/kubectl/quorum-go/ibft](https://github.com/ConsenSys/quorum-kubernetes/tree/89bddb3d01342f0e336d908de392b62bb8230bc5/playground/kubectl/quorum-go/ibft) with 3 member and 4 validator nodes.

The copy is being used to package the helm chart and publish it in the repo.

## Changelog

- From 0.2.x to 0.3.x
  - The predefined ETH accounts for the 4 validator nodes have changed:

    | Node | ETH account | private key | Password for unlocking account |
    |-------------------------|:-----------:|:-------:|:------------------------------------:|
    | `quorum-validator1` | `0xb5ced4530d6ccbb31b2b542fd9b4558b52296784` | `0x6b93a268f68239d321981125ecf24488920c6b3d900043d56fef66adb776abd5` | `Password` |<!-- # pragma: allowlist secret -->
    | `quorum-validator2` | `0x38134ca33fc3f82f91dae4b5e8bd94aff4a97ff5` | `0x8b360f3e5e4a83b71b2783c61c3026e0f1f0cd077a96b476f002f698a844f877` | `Password` |<!-- # pragma: allowlist secret -->
    | `quorum-validator3` | `0x40ba4082b30de5f17c3be9ed1b179e2af6533293` | `0xf4bd1e7d8c12ae9f23e56cbc79bb39aec69801ed66606e6e18186c2dd7cce731` | `Password` |<!-- # pragma: allowlist secret -->
    | `quorum-validator4` | `0x4048383303330169b536650fd54b9c742d6112bc` | `0xba3351cf7d27ff96dc23f9b8e1669688d94cc71957e33acaa1d7e07db740e6da` | `Password` |<!-- # pragma: allowlist secret -->

- From 0.1.x to 0.2.x
    - The 3 Member nodes (consisting of validator node and transaction manager Tessera) will not be deployed by default anymore.
    You can re-enable deployment of 3 members nodes by setting `config.members.enabled` to `true`.

## Usage

- [Here](./README.md#values) is a full list of all configuration values.
- The [values.yaml file](./values.yaml) shows the raw view of all configuration values.

### Quick install with internal services of type ClusterIP

This helm chart installs the Playground environment for a Quorum Cluster with static configuration values.

Install to namespace `quorum`

```bash
helm upgrade quorum ph-ethadapter/standalone-quorum --version=0.3.0 \
    --install \
    --namespace=quorum --create-namespace \
    --set config.storage.size="10Gi" \
    --set config.storage.type=pvc

```

### Additional helm options

Run `helm upgrade --helm` for full list of options.

1. Wait until installation has finished successfully and the deployment is up and running.

    Provide the `--wait` argument and time to wait (default is 5 minutes) via `--timeout`

    ```bash
    helm upgrade quorum ph-ethadapter/standalone-quorum --version=0.3.0 \
        --install \
        --wait --timeout=1200s \
        --namespace=quorum --create-namespace \
        --set config.storage.size="10Gi" \
        --set config.storage.type=pvc
       
    ```

### How to generate ETH accounts, private keys and keyfiles

Generate 4 address/privatekey pairs and their keyfiles - see [generator.sh](generator.sh)

Links:
- [https://geth.ethereum.org/docs/interface/managing-your-accounts](https://geth.ethereum.org/docs/interface/managing-your-accounts)
- [https://consensys.net/docs/goquorum/en/latest/configure-and-manage/configure/genesis-file/contracts-in-genesis/](https://consensys.net/docs/goquorum/en/latest/configure-and-manage/configure/genesis-file/contracts-in-genesis/)
- [https://github.com/ethereum/go-ethereum/issues/14831](https://github.com/ethereum/go-ethereum/issues/14831)
- [https://piyopiyo.medium.com/how-to-generate-ethereum-private-key-and-address-in-local-offline-environment-90294308593c](https://piyopiyo.medium.com/how-to-generate-ethereum-private-key-and-address-in-local-offline-environment-90294308593c)
- [https://stackoverflow.com/questions/66840794/ethereumjs-wallet-generate-is-not-a-function-error](https://stackoverflow.com/questions/66840794/ethereumjs-wallet-generate-is-not-a-function-error)

Output looks like this:

```text
Private Key 1
401f89555e79180e677b9065935750f6f462a049e621c2073595d3d0a93a5df5
Keyfile 1
{"address":"67d8f35e9b652c5c7493000eb840ff6fd6210604","crypto":{"cipher":"aes-128-ctr","ciphertext":"894f4f188567c9b65c0a791ba4b6118d19d794b550840bb250cc1fce78dcdf30","cipherparams":{"iv":"3b9e1d0d23ee03aefa330e0591faf2a8"},"kdf":"scrypt","kdfparams":{"dklen":32,"n":262144,"p":1,"r":8,"salt":"352e15e182d3f95bc8940bc68f29fe378cdb0e27635f296a767f317a8ae46b2b"},"mac":"eaef10f1f405fb7a8499e0dd52698dc47e0fe54a647fc94b0d07fed8b67e9931"},"id":"4bf8c4d4-273e-4587-b835-c2026a234206","version":3}

Private Key 2
6bc4ccaebc9ac083f4e7725ab1b7799da0c24f1c51b164125644b61a9cb33fc8
Keyfile 2
{"address":"81941b1ab7724ddeb3fca1bc528aa73e7dc1ebfd","crypto":{"cipher":"aes-128-ctr","ciphertext":"e4aae176092dc9ffa2ebfcbfc6aaa47ed0130c1d650da651fe2206be66a6865d","cipherparams":{"iv":"f7ca70dea77838f044471a3c1476917f"},"kdf":"scrypt","kdfparams":{"dklen":32,"n":262144,"p":1,"r":8,"salt":"d42760325d991ec651e6c61137bf23936f831ed5aa2d3a31895a6c9c9c361821"},"mac":"38d8b458dfac356070e4a4066986abe1c1f2dd9b9911b499c52fe4fc15b77b16"},"id":"e7279674-f593-4e90-944f-3049baf2faca","version":3}

Private Key 3
e0d2ae322a12bd90f30475cd1de931dca0937ee164d178bf3eb5d92e881e110c
Keyfile 3
{"address":"fa509f4c52a437bb56e943269168c85e80c94172","crypto":{"cipher":"aes-128-ctr","ciphertext":"9171888843f26d84c3bc6de746e0e060123eca26733f5775d88389b5a4da066d","cipherparams":{"iv":"163b18144834aec7727144efd78c47a3"},"kdf":"scrypt","kdfparams":{"dklen":32,"n":262144,"p":1,"r":8,"salt":"fb027943c64a1be55c82d9b35efae31dc60916047782bdada6fc773050f6f8ac"},"mac":"27db1ae07848d41d58208453f477f0c154c6e4207230d4d82138f324bbe0bc74"},"id":"167faad7-d485-496e-8618-9efb89e9436c","version":3}

Private Key 4
2770c96f3d88d213dd583f567a728c7c99a43f21f89388ebe11a4769f0a0bb2a
Keyfile 4
{"address":"833e8f2e12d06b991cc5af64a091a7512fd0a7cd","crypto":{"cipher":"aes-128-ctr","ciphertext":"1532914724edada2535a5c27851918922b360db843f36b82f56fb7312201acc1","cipherparams":{"iv":"9304276b5ce8d7af919adc88ea322fd2"},"kdf":"scrypt","kdfparams":{"dklen":32,"n":262144,"p":1,"r":8,"salt":"f6fc13df8e37eec123c9cfb72319d896444e6f12b0784cc81af17d3977e40e14"},"mac":"c657bb82eac69c6956f9e3094b2dc46450f5a4e5ffe2b8e83e9c51acf425bce4"},"id":"c00ee244-df3b-4f5c-b043-334d91fbbfc1","version":3}
```

## Values

| Key | Type | Default | Description |
|-----|------|---------|-------------|
| config.members.deploy | bool | `false` | Boolean flag whether 3 "member nodes" running a validator and transaction manager Tessera will be deployed or not. |
| config.storage.class | string | `""` | The name of the pre-existing storageClass used for the PVC (only needed if type is pvc) If type is pvc and class is empty string "" then Kubernetes will use the default storage class defined at cluster level |
| config.storage.size | string | `"2Gi"` | Size of storage |
| config.storage.type | string | `"local"` | Type of storage Either pvc or local (local=emptyDir) |

----------------------------------------------
Autogenerated from chart metadata using [helm-docs v1.5.0](https://github.com/norwoodj/helm-docs/releases/v1.5.0)
