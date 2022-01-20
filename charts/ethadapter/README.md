# ethadapter

![Version: 0.2.0](https://img.shields.io/badge/Version-0.2.0-informational?style=flat-square) ![Type: application](https://img.shields.io/badge/Type-application-informational?style=flat-square) ![AppVersion: 1.1](https://img.shields.io/badge/AppVersion-1.1-informational?style=flat-square)

A Helm chart for Pharma Ledger Ethereum Adapter Service

## Requirements

- [helm 3](https://helm.sh/docs/intro/install/)
- These mandatory configuration values:
  - RPC Address - The URL of the quorum node, e.g. `http://quorum-node-0-rpc:8545`
  - Smart Contract Address - The address of the smart contract, e.g. `0x1783aBc71903919382EFca91`
  - Smart Contract Abi
  <!-- # pragma: allowlist nextline secret -->
  - Org Account JSON - The confidential private key and address in JSON format, e.g. `{"privateKey":"0x1234567890abcdef", "address":"0x0987654321AbCdEf"}`

## Usage

- [Here](./README.md#values) is a full list of all configuration values.
- The [values.yaml file](./values.yaml) shows the raw view of all configuration values.

### Quick install with internal service of type ClusterIP

By default, this helm chart installs the Ethereum Adapter Service at an internal ClusterIP Service listening at port 3000.
This is to prevent exposing the service to the internet by accident!

It is recommended to put non-sensitive configuration values in an configuration file and pass sensitive/secret values via commandline.

1. Create configuration file, e.g. *my-config.yaml*

    ```yaml
    config:
      rpcAddress: "rpcAddress_value"
      smartContractAddress: "smartContractAddress_value"
      smartContractAbi: "smartContractAbi_value"
    ```

2. Install via helm to namespace `default` either by passing sensitive *Org Account JSON* value in JSON format as escaped string

    ```bash
    helm upgrade my-release-name ph-ethadapter/ethadapter --version=0.2.0 \
        --install \
        --values my-config.yaml \
        --set-string secrets.orgAccountJson="\{ \"key1\": \"value1\" \, \"key2\": \"value2\" \}"
    ```

3. or pass sensitive *Org Account JSON* value in JSON format as base64 encoded string

    ```bash
    helm upgrade my-release-name ph-ethadapter/ethadapter --version=0.2.0 \
        --install \
        --values my-config.yaml \
        --set-string secrets.orgAccountJsonBase64="eyAia2V5IjogInZhbHVlIiB9"
    ```

### Expose Service via Load Balancer

In order to expose the service **directly** by an **own dedicated** Load Balancer, just **add** `service.type` with value `LoadBalancer` to your config file (in order to override the default value which is `ClusterIP`).

**Please note:** At AWS using `service.type` = `LoadBalancer` is not recommended any more, as it creates a Classic Load Balancer. Use [AWS Load Balancer Controller](https://kubernetes-sigs.github.io/aws-load-balancer-controller/v2.3/) with an ingress instead. A full sample is provided later in the docs. Using an Application Load Balancer (managed by AWS LB Controller) increases security (e.g. by using a Web Application Firewall for your http based traffic) and provides more features like hostname, pathname routing or built-in authentication mechanism via OIDC or AWS Cognito.

Configuration file *my-config.yaml*

```yaml
service:
  type: LoadBalancer

config:
  rpcAddress: "rpcAddress_value"
  smartContractAddress: "smartContractAddress_value"
  smartContractAbi: "smartContractAbi_value"
```

There are more configuration options available like customizing the port and configuring the Load Balancer via annotations (e.g. for configuring SSL Listener).

**Also note:** Annotations are very specific to your environment/cloud provider, see [Kubernetes Service Reference](https://kubernetes.io/docs/concepts/services-networking/service/#ssl-support-on-aws) for more information. For Azure, take a look [here](https://kubernetes-sigs.github.io/cloud-provider-azure/topics/loadbalancer/#loadbalancer-annotations).

Sample for AWS (SSL and listening on port 4567 instead 3000 which is the default):

```yaml
service:
  type: LoadBalancer
  port: 4567
  annotations:
    service.beta.kubernetes.io/aws-load-balancer-ssl-cert: arn:aws:acm:us-east-1:123456789012:certificate/12345678-1234-1234-1234-123456789012
    service.beta.kubernetes.io/aws-load-balancer-backend-protocol: http
    service.beta.kubernetes.io/aws-load-balancer-ssl-ports: "4567"
    # https://docs.aws.amazon.com/de_de/elasticloadbalancing/latest/classic/elb-security-policy-table.html
    service.beta.kubernetes.io/aws-load-balancer-ssl-negotiation-policy: "ELBSecurityPolicy-TLS-1-2-2017-01"

# further config
```

### AWS Load Balancer Controler: Expose Service via Ingress

Note: You need the [AWS Load Balancer Controller](https://kubernetes-sigs.github.io/aws-load-balancer-controller/) installed and configured properly.

1. Enable ingress
2. Add *host*, *path* *`/*`* and *pathType* `ImplementationSpecific`
3. Add annotations for AWS LB Controller
4. A SSL certificate at AWS Certificate Manager (either for the hostname, here `ethadapter.mydomain.com` or wildcard `*.mydomain.com`)

Configuration file *my-config.yaml*

```yaml
ingress:
  enabled: true
  # Let AWS LB Controller handle the ingress (default className is alb)
  # Note: Use className instead of annotation 'kubernetes.io/ingress.class' which is deprecated since 1.18
  # For Kubernetes >= 1.18 it is required to have an existing IngressClass object.
  # See: https://kubernetes.io/docs/concepts/services-networking/ingress/#deprecated-annotation
  className: alb
  hosts:
    - host: ethadapter.mydomain.com
      # Path must be /* for ALB to match all paths
      paths:
        - path: /*
          pathType: ImplementationSpecific
  # For full list of annotations for AWS LB Controller, see https://kubernetes-sigs.github.io/aws-load-balancer-controller/v2.3/guide/ingress/annotations/
  annotations:
    # The ARN of the existing SSL Certificate at AWS Certificate Manager
    alb.ingress.kubernetes.io/certificate-arn: arn:aws:acm:REGION:ACCOUNT_ID:certificate/CERTIFICATE_ID
    # The name of the ALB group, can be used to configure a single ALB by multiple ingress objects
    alb.ingress.kubernetes.io/group.name: default
    # Specifies the HTTP path when performing health check on targets.
    alb.ingress.kubernetes.io/healthcheck-path: /check
    # Specifies the port used when performing health check on targets.
    alb.ingress.kubernetes.io/healthcheck-port: traffic-port
    # Specifies the HTTP status code that should be expected when doing health checks against the specified health check path.
    alb.ingress.kubernetes.io/success-codes: "200"
    # Listen on HTTPS protocol at port 3000 at the ALB
    alb.ingress.kubernetes.io/listen-ports: '[{"HTTPS":3000}]'
    # Allow access from a specific IP address only, e.g. from the NAT Gateway of your EPI Cluster
    alb.ingress.kubernetes.io/inbound-cidrs: 8.8.8.8/32
    # Use internet facing
    alb.ingress.kubernetes.io/scheme: internet-facing
    # Use most current (as of Dec 2021) encryption ciphers
    alb.ingress.kubernetes.io/ssl-policy: ELBSecurityPolicy-TLS-1-2-Ext-2018-06
    # Use target type IP which is the case if the service type is ClusterIP
    alb.ingress.kubernetes.io/target-type: ip

config:
  rpcAddress: "rpcAddress_value"
  smartContractAddress: "smartContractAddress_value"
  smartContractAbi: "smartContractAbi_value"
```

### Additional helm options

Run `helm upgrade --helm` for full list of options.

1. Install to other namespace

    You can install into other namespace than `default` by setting the `--namespace` parameter, e.g.

    ```bash
    helm upgrade my-release-name ph-ethadapter/ethadapter --version=0.2.0 \
        --install \
        --namespace=my-namespace \
        --values my-config.yaml \
        --set-string secrets.orgAccountJson="\{ \"key1\": \"value1\" \, \"key2\": \"value2\"\}"
    ```

2. Wait until installation has finished successfully and the deployment is up and running.

    Provide the `--wait` argument and time to wait (default is 5 minutes) via `--timeout`

    ```bash
    helm upgrade my-release-name ph-ethadapter/ethadapter --version=0.2.0 \
        --install \
        --wait --timeout=600s \
        --values my-config.yaml \
        --set-string secrets.orgAccountJson="\{ \"key1\": \"value1\" \, \"key2\": \"value2\" \}"
    ```

### Potential issues

1. `Error: admission webhook "vingress.elbv2.k8s.aws" denied the request: invalid ingress class: IngressClass.networking.k8s.io "alb" not found`

    **Description:** This error only applies to Kubernetes >= 1.18 and indicates that no matching *IngressClass* object was found.

    **Solution:** Either declare an appropriate IngressClass or omit *className* and add annotation `kubernetes.io/ingress.class`

    Further information:

     - [Kubernetes IngressClass](https://kubernetes.io/docs/concepts/services-networking/ingress/#ingress-class)
     - [AWS Load Balancer controller documentation](https://kubernetes-sigs.github.io/aws-load-balancer-controller/v2.3/guide/ingress/ingress_class/)

## Helm Unittesting

[helm-unittest](https://github.com/quintush/helm-unittest) is being used for testing the output of the helm chart.
Tests can be found in [tests](./tests)

## Manual Tests

See [Helm Debugging Templates](https://helm.sh/docs/chart_template_guide/debugging/)

```bash
mkdir -p ./testresults
rm -rf ./testresults/*
# https://github.com/helm/helm/issues/5618
echo ""
echo "Default values and secret passed as String"
helm template test-ethadapter ph-ethadapter/ethadapter --version=0.2.0 --values ./tests/data/default.yaml --set-string secrets.orgAccountJson="\{ \"key\": \"value\" \}" > ./tests/results/result_default2.yaml

echo ""
echo "Default values and secret passed as base64 encoded String"
helm template test-ethadapter ph-ethadapter/ethadapter --version=0.2.0 --values ./tests/data/default.yaml --set-string secrets.orgAccountJsonBase64="eyAia2V5IjogInZhbHVlIiB9" > ./tests/results/result_default_base64.yaml

echo ""
echo "LoadBalancer"
helm template test-ethadapter ph-ethadapter/ethadapter --version=0.2.0 --values ./tests/data/loadbalancer.yaml --set-string secrets.orgAccountJsonBase64="eyAia2V5IjogInZhbHVlIiB9" > ./tests/results/result_loadbalancer.yaml

echo ""
echo "LoadBalancer and annotations"
helm template test-ethadapter ph-ethadapter/ethadapter --version=0.2.0 --values ./tests/data/loadbalancer_annotations.yaml --set-string secrets.orgAccountJsonBase64="eyAia2V5IjogInZhbHVlIiB9" > ./tests/results/result_loadbalancer_annotations.yaml

echo ""
echo "Ingress via AWS LB Controller"
helm template test-ethadapter ph-ethadapter/ethadapter --version=0.2.0 --values ./tests/data/aws_lb_controller_ingress.yaml --set-string secrets.orgAccountJsonBase64="eyAia2V5IjogInZhbHVlIiB9" > ./tests/results/result_aws_lb_controller_ingress.yaml
```

## Maintainers

| Name | Email | Url |
| ---- | ------ | --- |
| tgip-work |  | https://github.com/tgip-work |

## Values

| Key | Type | Default | Description |
|-----|------|---------|-------------|
| affinity | object | `{}` | Affinity for scheduling a pod. See [https://kubernetes.io/docs/concepts/scheduling-eviction/assign-pod-node/](https://kubernetes.io/docs/concepts/scheduling-eviction/assign-pod-node/) |
| autoscaling.enabled | bool | `false` | Whether to enable horizontal pod autoscaling or not. See [https://kubernetes.io/de/docs/tasks/run-application/horizontal-pod-autoscale/](https://kubernetes.io/de/docs/tasks/run-application/horizontal-pod-autoscale/) |
| autoscaling.maxReplicas | int | `100` | The maximum number of replicas in case autoscaling is enabled. |
| autoscaling.minReplicas | int | `1` | The minimum number of replicas in case autoscaling is enabled. |
| autoscaling.targetCPUUtilizationPercentage | int | `80` | The CPU utilization in percentage as a target for autoscaling. |
| config.rpcAddress | string | `"http://quorum-member1.quorum:8545"` | URL of the Quorum node |
| config.smartContractAbi | string | `""` | Abi (interface) of the Smart Contract. If not set/empty, tries to get value from ConfigMap '.config.smartContractConfigMapName' with key '.config.smartContractConfigMapAbiKey' |
| config.smartContractAddress | string | `""` | Address of the Smart Contract. If not set/empty, tries to get value from ConfigMap '.config.smartContractConfigMapName' with key '.config.smartContractConfigMapAddressKey' |
| config.smartContractConfigMapAbiKey | string | `"abi"` | The key of the Abi in the existing ConfigMap in case smartContractAbi is not explictly defined |
| config.smartContractConfigMapAddressKey | string | `"address"` | The key of the Address in the existing ConfigMap in case smartContractAddress is not explictly defined |
| config.smartContractConfigMapName | string | `"smartcontract-anchoring-info"` | The name of the existing ConfigMap to look for in case values are not explictly defined via smartContractAddress and smartContractAbi |
| fullnameOverride | string | `""` | fullnameOverride completely replaces the generated name. From [https://stackoverflow.com/questions/63838705/what-is-the-difference-between-fullnameoverride-and-nameoverride-in-helm](https://stackoverflow.com/questions/63838705/what-is-the-difference-between-fullnameoverride-and-nameoverride-in-helm) |
| image.pullPolicy | string | `"IfNotPresent"` | Image Pull Policy |
| image.repository | string | `"public.ecr.aws/n4q1q0z2/pharmaledger-ethadapter"` | The repository of the container image |
| image.tag | string | `""` | Overrides the image tag whose default is the chart appVersion. |
| imagePullSecrets | list | `[]` | Secret(s) for pulling an container image from a private registry. See [https://kubernetes.io/docs/tasks/configure-pod-container/pull-image-private-registry/](https://kubernetes.io/docs/tasks/configure-pod-container/pull-image-private-registry/) |
| ingress.annotations | object | `{}` | Ingress annotations. For AWS LB Controller, see [https://kubernetes-sigs.github.io/aws-load-balancer-controller/v2.3/guide/ingress/annotations/](https://kubernetes-sigs.github.io/aws-load-balancer-controller/v2.3/guide/ingress/annotations/) For Azure Application Gateway Ingress Controller, see [https://azure.github.io/application-gateway-kubernetes-ingress/annotations/](https://azure.github.io/application-gateway-kubernetes-ingress/annotations/) For NGINX Ingress Controller, see [https://kubernetes.github.io/ingress-nginx/user-guide/nginx-configuration/annotations/](https://kubernetes.github.io/ingress-nginx/user-guide/nginx-configuration/annotations/) For Traefik Ingress Controller, see [https://doc.traefik.io/traefik/routing/providers/kubernetes-ingress/#annotations](https://doc.traefik.io/traefik/routing/providers/kubernetes-ingress/#annotations) |
| ingress.className | string | `""` | The className specifies the IngressClass object which is responsible for that class. Note for Kubernetes >= 1.18 it is required to have an existing IngressClass object. If IngressClass object does not exists, omit className and add the deprecated annotation 'kubernetes.io/ingress.class' instead. For Kubernetes < 1.18 either use className or annotation 'kubernetes.io/ingress.class'. See https://kubernetes.io/docs/concepts/services-networking/ingress/#ingress-class |
| ingress.enabled | bool | `false` | Whether to create ingress or not. Note: For ingress an Ingress Controller (e.g. AWS LB Controller, NGINX Ingress Controller, Traefik, ...) is required and service.type should be ClusterIP or NodePort depending on your configuration |
| ingress.hosts[0].host | string | `"ethadapter.some-pharma-company.com"` | The FQDN/hostname |
| ingress.hosts[0].paths[0].path | string | `"/"` | The Ingress Path. See [https://kubernetes.io/docs/concepts/services-networking/ingress/#examples](https://kubernetes.io/docs/concepts/services-networking/ingress/#examples) Note: For Ingress Controllers like AWS LB Controller see their specific documentation. |
| ingress.hosts[0].paths[0].pathType | string | `"ImplementationSpecific"` | The type of path. This value is required since Kubernetes 1.18. For Ingress Controllers like AWS LB Controller or Traefik it is usually required to set its value to ImplementationSpecific See [https://kubernetes.io/docs/concepts/services-networking/ingress/#path-types](https://kubernetes.io/docs/concepts/services-networking/ingress/#path-types) and [https://kubernetes.io/blog/2020/04/02/improvements-to-the-ingress-api-in-kubernetes-1.18/](https://kubernetes.io/blog/2020/04/02/improvements-to-the-ingress-api-in-kubernetes-1.18/) |
| ingress.tls | list | `[]` |  |
| nameOverride | string | `""` | nameOverride replaces the name of the chart in the Chart.yaml file, when this is used to construct Kubernetes object names. From [https://stackoverflow.com/questions/63838705/what-is-the-difference-between-fullnameoverride-and-nameoverride-in-helm](https://stackoverflow.com/questions/63838705/what-is-the-difference-between-fullnameoverride-and-nameoverride-in-helm) |
| nodeSelector | object | `{}` | Node Selectors in order to assign pods to certain nodes. See [https://kubernetes.io/docs/concepts/scheduling-eviction/assign-pod-node/](https://kubernetes.io/docs/concepts/scheduling-eviction/assign-pod-node/) |
| podAnnotations | object | `{}` | Annotations added to the pod |
| podSecurityContext | object | `{}` | Security Context for the pod. See [https://kubernetes.io/docs/tasks/configure-pod-container/security-context/#set-the-security-context-for-a-pod](https://kubernetes.io/docs/tasks/configure-pod-container/security-context/#set-the-security-context-for-a-pod) |
| replicaCount | int | `1` | The number of replicas if autoscaling is false |
| resources | object | `{}` | Resource constraints for a pod |
| secrets.orgAccountJson | string | `""` | Org Account in JSON format.  If not set/empty and also orgAccountJsonBase64 is not set/empty, tries to get value from Secret '.secrets.smartContractSecretName' with key '.secrets.smartContractSecretOrgAccountJsonKey' |
| secrets.orgAccountJsonBase64 | string | `""` | Org Account in JSON format base64 encoded.  If not set/empty and also orgAccountJson is not set/empty, tries to get value from Secret '.secrets.smartContractSecretName' with key '.secrets.smartContractSecretOrgAccountJsonKey' |
| secrets.smartContractSecretName | string | `"smartcontract-org-account"` | The name of the existing Secret to look for in case orgAccountJson or orgAccountJsonBase64 is not explictly set |
| secrets.smartContractSecretOrgAccountJsonKey | string | `"infoJson"` | The key of Org Account Json in the existing Secret in case orgAccountJson or orgAccountJsonBase64 is not explictly set |
| securityContext | object | `{}` | Security Context for the container. See [https://kubernetes.io/docs/tasks/configure-pod-container/security-context/#set-the-security-context-for-a-container](https://kubernetes.io/docs/tasks/configure-pod-container/security-context/#set-the-security-context-for-a-container) |
| service.annotations | object | `{}` | Annotations for the service. See AWS, see [https://kubernetes.io/docs/concepts/services-networking/service/#ssl-support-on-aws](https://kubernetes.io/docs/concepts/services-networking/service/#ssl-support-on-aws) For Azure, see [https://kubernetes-sigs.github.io/cloud-provider-azure/topics/loadbalancer/#loadbalancer-annotations](https://kubernetes-sigs.github.io/cloud-provider-azure/topics/loadbalancer/#loadbalancer-annotations) |
| service.port | int | `3000` | Port where the service will be exposed |
| service.type | string | `"ClusterIP"` | Either ClusterIP, NodePort or LoadBalancer. See [https://kubernetes.io/docs/concepts/services-networking/service/](https://kubernetes.io/docs/concepts/services-networking/service/) |
| serviceAccount.annotations | object | `{}` | Annotations to add to the service account |
| serviceAccount.create | bool | `false` | Specifies whether a service account should be created |
| serviceAccount.name | string | `""` | The name of the service account to use. If not set and create is true, a name is generated using the fullname template |
| tolerations | list | `[]` | Tolerations for scheduling a pod. See [https://kubernetes.io/docs/concepts/scheduling-eviction/taint-and-toleration/](https://kubernetes.io/docs/concepts/scheduling-eviction/taint-and-toleration/) |

----------------------------------------------
Autogenerated from chart metadata using [helm-docs v1.5.0](https://github.com/norwoodj/helm-docs/releases/v1.5.0)
