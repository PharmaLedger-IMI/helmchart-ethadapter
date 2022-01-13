# pharmaledger-helmcharts

Helm Charts for Pharma Ledger

## Requirements

- [helm 3](https://helm.sh/docs/intro/install/)

## Installing the Helm Repository

Add the repo as follow

```bash
helm repo add ph-ethadapter https://pharmaledger-imi.github.io/helmchart-ethadapter
```

Then you can run `helm search repo ph-ethadapter` to see the chart(s). On installation use the `--version` flag to specify a chart version.

## Charts

You will find the Helm charts in subfolders of [charts](charts).

| Name | Description |
| ---- | ------ |
| [ethadapter](charts/ethadapter/README.md) | A Helm chart for Pharma Ledger Ethereum Adapter Service |
| [epi](charts/epi/README.md) | A Helm chart for Pharma Ledger epi (electronic product information) application |

## Helm Unittesting

[helm-unittest](https://github.com/quintush/helm-unittest) is being used for testing the output of the helm chart.
Samples: See [ethadapter/tests](./charts/ethadapter/tests)
