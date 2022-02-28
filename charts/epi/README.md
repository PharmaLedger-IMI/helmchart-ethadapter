# epi

![Version: 0.2.0](https://img.shields.io/badge/Version-0.2.0-informational?style=flat-square) ![Type: application](https://img.shields.io/badge/Type-application-informational?style=flat-square) ![AppVersion: poc.1.6](https://img.shields.io/badge/AppVersion-poc.1.6-informational?style=flat-square)

A Helm chart for Pharma Ledger epi (electronic product information) application

## Requirements

- [helm 3](https://helm.sh/docs/intro/install/)
- These mandatory configuration values:
  - Domain - The Domain - e.g. `epipoc`
  - Sub Domain - The Sub Domain - e.g. `epipoc.my-company`
  - Vault Domain - The Vault Domain - e.g. `vault.my-company`
  - ethadapterUrl - The Full URL of the Ethadapter including protocol and port -  e.g. "https://ethadapter.my-company.com:3000"
  - bdnsHosts - The Centrally managed and provided BDNS Hosts Config -

## Usage

- [Here](./README.md#values) is a full list of all configuration values.
- The [values.yaml file](./values.yaml) shows the raw view of all configuration values.

## Changelog

- From 0.1.x to 0.2.x - Technical release: Significant changes! Please uninstall old versions first! Upgrade from 0.1.x not tested and not guaranteed!
  - Uses Helm hooks for Init and Cleanup
  - Optimized Build process: SeedsBackup will only be created if the underlying Container image has changed, e.g. in case of an upgrade!
  - Readiness probe implemented. Application container is considered as *ready* after build process has been finished.
  - Value `config.ethadapterUrl` has changed from `https://ethadapter.my-company.com:3000` to `http://ethadapter.ethadapter:3000` in order to reflect changes in [ethadapter](https://github.com/PharmaLedger-IMI/helmchart-ethadapter/tree/epi-improve-build/charts/ethadapter).
  - Value `persistence.storageClassName` has changed from `gp2` to empty string `""` in order to remove pre-defined setting for AWS and to be cloud-agnostic by default.
  - Configurable sleep time between start of apihub and build process (`config.sleepTime`).
  - Configuration options for PersistentVolumeClaim
  - Configuration has been prepared for running as non-root user (commented out yet, see [values.yaml `podSecurityContext` and `securityContext`](./values.yaml)).
  - Minor optimizations at Kubernetes resources, e.g. set sizeLimit of temporary shared volume, explictly set readOnly flags at volumeMounts.

## Helm Lifecycle and Kubernetes Resources Lifetime

This helm chart uses Helm [hooks](https://helm.sh/docs/topics/charts_hooks/) in order to install, upgrade and manage the application and its resources.

```mermaid
sequenceDiagram
  participant PIN as pre-install
  participant PUP as pre-upgrade
  participant I as install
  participant U as uninstall
  participant PUN as post-uninstall
  Note over PIN,PUN: PersistentVolumeClaim
  Note over PIN,PUN: ConfigMap SeedsBackup
  Note over PIN:Init Job
  Note over PIN:ConfigMaps Init
  Note over PIN:ServiceAccount Init
  Note over PIN:Role Init
  Note over PIN:RoleBinding Init
  note right of PIN: Note: The Init Job stores <br/>Seeds in Configmap SeedsBackup and <br/> is either executed by a) pre-install hook or<br/>b)pre-upgrade hook
  Note over PUP,U:Deployment
  Note over PUP,U:ConfigMap build-info
  Note over PUP,U:Configmaps for application
  Note over PUP,U:Service
  Note over PUP,U:Ingress
  Note over PUP,U:ServiceAccount
  Note over PUP:Init Job<br/>and more<br/>(see pre-install)
  Note over PUN:Cleanup Job
  Note over PUN:ServiceAccount Cleanup
  Note over PUN:Role Cleanup
  Note over PUN:RoleBinding Cleanup
  note right of PUN: Note: The Cleanup job<br/>1. deletes PersistentVolumeClaim (optional)<br/>2. creates final backup of ConfigMap SeedsBackup<br/>3. deletes ConfigMap SeedsBackup
```

## Init Job

The Init Job is an important step and will be executed on helm [hooks](https://helm.sh/docs/topics/charts_hooks/) `pre-install` and `pre-upgrade`.
Its pod consists of three containers, two init containers and one main container.

```mermaid
flowchart LR
A(Init Container 1:<br/>Check necessity for build process) -->B(Init Container 2:<br/>Run build process if necessary)
B --> C(Main Container:<br/>Write/Update ConfigMap Seedsbackup)
```

### Init Job Details

1. On `helm install` and `helm upgrade`, helm will deploy a Kubernete Job named *job-init* which schedules a pod consisting of two Init Containers and one Main Container.

```mermaid
flowchart LR
A(Helm pre-install/pre-upgrade hook) -->|deploys| B(Init Job)
B -->|schedules| C(Init Pod)
```

2. The first Init Container runs `kubectl` command to check existance of ConfigMap `build-info` which contains information about latest successful build process.
   1. If ConfigMap `build-info` does not exist or latest build process does not match current epi application container image, then a *signal* file will be written to a shared volume between containers.
   2. Otherwise the build process has already been executed for current application container image.

```mermaid
flowchart LR
D(Init Container<br/>Kubectl) --> E{ConfigMap build-info<br/>exists and<br/>matches current<br/>container image?}
E -->|not exists| F[Write signal file to shared data volume]
F --> G[Exit Init Container<br/>Kubectl]
E -->|exists| G
```

3. The second Init Container uses the container image of the epi application and checks existance of *Signal* file from first Init Container.
4. If it does not exists, then no build process shall run and the container exists.
5. If the *Signal* file exists, then
   1. Starts the apihub server (`npm run server`), waits for a short period of time and then starts the build process (`npm run build-all`).
   2. After build process, it writes the SeedsBackup file on a shared temporary volume between init and main container.

```mermaid
flowchart LR
D(Init Container<br/>application) --> E{Signal file exists?}
E -->|yes, exists| F[start apihub server]
F --> G[sleep short time]
G --> H[build process]
H --> I[write SeedsBackup file to shared data with main container]
I --> J
E -->|no, does not exist| J[Exit Init Container<br/>application]
```

6. The Main Container has kubectl installed and checks if SeedsBackup file was handed over by Init Container.

```mermaid
flowchart LR
L(Main Container) --> M{SeedsBackup file exists?}
M -->|exists| N[Create ConfigMap SeedsBackup for current Image]
N --> O[Update ConfigMap SeedsBackup]
O --> P
M -->|not exists| P[Exit Pod]
```

After completion of the *Init Job* the application container will be deployed/restarted with the current *ConfigMap SeedsBackup*.

## Cleanup Job

On deletion/uninstall of the helm chart a Kubernetes `cleanup` will be deployed in order to delete unmanaged helm resources created by helm hooks at `pre-install`.
These resources are:

1. Init Job - The Init Job was created on pre-install/pre-upgrade and will remain after its execution.
2. PersistentVolumeClaim - In case the PersistentVolumeClaim shall not be deleted on deletion of the helm release, set `persistence.deletePvcOnUninstall` to `false`.
3. ConfigMap SeedsBackup - Prior to deletion of the ConfigMap, a backup ConfigMap will be created with naming schema `{HELM_RELEASE_NAME}-seedsbackup-{IMAGE_TAG}-final-backup-{EPOCH_IN_SECONDS}`, e.g. `epi-seedsbackup-poc.1.6-final-backup-1646063552`

### Quick install with internal service of type ClusterIP

By default, this helm chart installs the Ethereum Adapter Service at an internal ClusterIP Service listening at port 3000.
This is to prevent exposing the service to the internet by accident!

It is recommended to put non-sensitive configuration values in an configuration file and pass sensitive/secret values via commandline.

1. Create configuration file, e.g. *my-config.yaml*

    ```yaml
    config:
      domain: "domain_value"
      subDomain: "subDomain_value"
      vaultDomain: "vaultDomain_value"
      ethadapterUrl: "https://ethadapter.my-company.com:3000"
      bdnsHosts: |-
        # ... content of the BDNS Hosts file ...

    ```

2. Install via helm to namespace `default`

    ```bash
    helm upgrade my-release-name ph-ethadapter/epi --version=0.2.0 \
        --install \
        --values my-config.yaml \
    ```

### Expose Service via Load Balancer

In order to expose the service **directly** by an **own dedicated** Load Balancer, just **add** `service.type` with value `LoadBalancer` to your config file (in order to override the default value which is `ClusterIP`).

**Please note:** At AWS using `service.type` = `LoadBalancer` is not recommended any more, as it creates a Classic Load Balancer. Use [AWS Load Balancer Controller](https://kubernetes-sigs.github.io/aws-load-balancer-controller/v2.3/) with an ingress instead. A full sample is provided later in the docs. Using an Application Load Balancer (managed by AWS LB Controller) increases security (e.g. by using a Web Application Firewall for your http based traffic) and provides more features like hostname, pathname routing or built-in authentication mechanism via OIDC or AWS Cognito.

Configuration file *my-config.yaml*

```yaml
service:
  type: LoadBalancer

config:
  # ... config section keys and values ...
```

There are more configuration options available like customizing the port and configuring the Load Balancer via annotations (e.g. for configuring SSL Listener).

**Also note:** Annotations are very specific to your environment/cloud provider, see [Kubernetes Service Reference](https://kubernetes.io/docs/concepts/services-networking/service/#ssl-support-on-aws) for more information. For Azure, take a look [here](https://kubernetes-sigs.github.io/cloud-provider-azure/topics/loadbalancer/#loadbalancer-annotations).

Sample for AWS (SSL and listening on port 1234 instead 80 which is the default):

```yaml
service:
  type: LoadBalancer
  port: 80
  annotations:
    service.beta.kubernetes.io/aws-load-balancer-ssl-cert: arn:aws:acm:us-east-1:123456789012:certificate/12345678-1234-1234-1234-123456789012
    service.beta.kubernetes.io/aws-load-balancer-backend-protocol: http
    service.beta.kubernetes.io/aws-load-balancer-ssl-ports: "80"
    # https://docs.aws.amazon.com/de_de/elasticloadbalancing/latest/classic/elb-security-policy-table.html
    service.beta.kubernetes.io/aws-load-balancer-ssl-negotiation-policy: "ELBSecurityPolicy-TLS-1-2-2017-01"

# further config
```

### AWS Load Balancer Controler: Expose Service via Ingress

Note: You need the [AWS Load Balancer Controller](https://kubernetes-sigs.github.io/aws-load-balancer-controller/) installed and configured properly.

1. Enable ingress
2. Add *host*, *path* *`/*`* and *pathType* `ImplementationSpecific`
3. Add annotations for AWS LB Controller
4. A SSL certificate at AWS Certificate Manager (either for the hostname, here `epi.mydomain.com` or wildcard `*.mydomain.com`)

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
    - host: epi.mydomain.com
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
    alb.ingress.kubernetes.io/healthcheck-path: /
    # Specifies the port used when performing health check on targets.
    alb.ingress.kubernetes.io/healthcheck-port: traffic-port
    # Specifies the HTTP status code that should be expected when doing health checks against the specified health check path.
    alb.ingress.kubernetes.io/success-codes: "200"
    # Listen on HTTPS protocol at port 443 at the ALB
    alb.ingress.kubernetes.io/listen-ports: '[{"HTTPS":443}]'
    # Use internet facing
    alb.ingress.kubernetes.io/scheme: internet-facing
    # Use most current (as of Dec 2021) encryption ciphers
    alb.ingress.kubernetes.io/ssl-policy: ELBSecurityPolicy-TLS-1-2-Ext-2018-06
    # Use target type IP which is the case if the service type is ClusterIP
    alb.ingress.kubernetes.io/target-type: ip

config:
  # ... config section keys and values ...
```

### Additional helm options

Run `helm upgrade --helm` for full list of options.

1. Install to other namespace

    You can install into other namespace than `default` by setting the `--namespace` parameter, e.g.

    ```bash
    helm upgrade my-release-name ph-ethadapter/epi --version=0.2.0 \
        --install \
        --namespace=my-namespace \
        --values my-config.yaml \
    ```

2. Wait until installation has finished successfully and the deployment is up and running.

    Provide the `--wait` argument and time to wait (default is 5 minutes) via `--timeout`

    ```bash
    helm upgrade my-release-name ph-ethadapter/epi --version=0.2.0 \
        --install \
        --wait --timeout=600s \
        --values my-config.yaml \
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

## Maintainers

| Name | Email | Url |
| ---- | ------ | --- |
| tgip-work |  | https://github.com/tgip-work |

## Values

| Key | Type | Default | Description |
|-----|------|---------|-------------|
| affinity | object | `{}` | Affinity for scheduling a pod. See [https://kubernetes.io/docs/concepts/scheduling-eviction/assign-pod-node/](https://kubernetes.io/docs/concepts/scheduling-eviction/assign-pod-node/) |
| config | object | `{"bdnsHosts":"{\n  \"epipoc\": {\n      \"anchoringServices\": [\n          \"$ORIGIN\"\n      ],\n      \"notifications\": [\n          \"$ORIGIN\"\n      ]\n  },\n  \"epipoc.my-company\": {\n      \"brickStorages\": [\n          \"$ORIGIN\"\n      ],\n      \"anchoringServices\": [\n          \"$ORIGIN\"\n      ],\n      \"notifications\": [\n          \"$ORIGIN\"\n      ]\n  },\n  \"epipoc.other\": {\n      \"brickStorages\": [\n          \"https://epipoc.other-company.com\"\n      ],\n      \"anchoringServices\": [\n          \"https://epipoc.other-company.com\"\n      ],\n      \"notifications\": [\n          \"https://epipoc.other-company.com\"\n      ]\n  },\n  \"vault.my-company\": {\n      \"replicas\": [],\n      \"brickStorages\": [\n          \"$ORIGIN\"\n      ],\n      \"anchoringServices\": [\n          \"$ORIGIN\"\n      ],\n      \"notifications\": [\n          \"$ORIGIN\"\n      ]\n  }\n}","domain":"epipoc","ethadapterUrl":"http://ethadapter.ethadapter:3000","sleepTime":"10s","subDomain":"epipoc.my-company","vaultDomain":"vault.my-company"}` | Configuration. Will be put in ConfigMaps. |
| config.bdnsHosts | string | `"{\n  \"epipoc\": {\n      \"anchoringServices\": [\n          \"$ORIGIN\"\n      ],\n      \"notifications\": [\n          \"$ORIGIN\"\n      ]\n  },\n  \"epipoc.my-company\": {\n      \"brickStorages\": [\n          \"$ORIGIN\"\n      ],\n      \"anchoringServices\": [\n          \"$ORIGIN\"\n      ],\n      \"notifications\": [\n          \"$ORIGIN\"\n      ]\n  },\n  \"epipoc.other\": {\n      \"brickStorages\": [\n          \"https://epipoc.other-company.com\"\n      ],\n      \"anchoringServices\": [\n          \"https://epipoc.other-company.com\"\n      ],\n      \"notifications\": [\n          \"https://epipoc.other-company.com\"\n      ]\n  },\n  \"vault.my-company\": {\n      \"replicas\": [],\n      \"brickStorages\": [\n          \"$ORIGIN\"\n      ],\n      \"anchoringServices\": [\n          \"$ORIGIN\"\n      ],\n      \"notifications\": [\n          \"$ORIGIN\"\n      ]\n  }\n}"` | Centrally managed and provided BDNS Hosts Config |
| config.domain | string | `"epipoc"` | The Domain, e.g. "epipoc" |
| config.ethadapterUrl | string | `"http://ethadapter.ethadapter:3000"` | The Full URL of the Ethadapter including protocol and port, e.g. "https://ethadapter.my-company.com:3000" |
| config.subDomain | string | `"epipoc.my-company"` | The Subdomain, should be domain.company, e.g. epipoc.my-company |
| config.vaultDomain | string | `"vault.my-company"` | The Vault domain, should be vault.company, e.g. vault.my-company |
| deploymentStrategy.type | string | `"Recreate"` |  |
| fullnameOverride | string | `""` | fullnameOverride completely replaces the generated name. From [https://stackoverflow.com/questions/63838705/what-is-the-difference-between-fullnameoverride-and-nameoverride-in-helm](https://stackoverflow.com/questions/63838705/what-is-the-difference-between-fullnameoverride-and-nameoverride-in-helm) |
| image.pullPolicy | string | `"IfNotPresent"` | Image Pull Policy |
| image.repository | string | `"public.ecr.aws/n4q1q0z2/pharmaledger-epi"` | The repository of the container image |
| image.tag | string | `""` | Overrides the image tag whose default is the chart appVersion. |
| imagePullSecrets | list | `[]` | Secret(s) for pulling an container image from a private registry. See [https://kubernetes.io/docs/tasks/configure-pod-container/pull-image-private-registry/](https://kubernetes.io/docs/tasks/configure-pod-container/pull-image-private-registry/) |
| ingress.annotations | object | `{}` | Ingress annotations. For AWS LB Controller, see [https://kubernetes-sigs.github.io/aws-load-balancer-controller/v2.3/guide/ingress/annotations/](https://kubernetes-sigs.github.io/aws-load-balancer-controller/v2.3/guide/ingress/annotations/) For Azure Application Gateway Ingress Controller, see [https://azure.github.io/application-gateway-kubernetes-ingress/annotations/](https://azure.github.io/application-gateway-kubernetes-ingress/annotations/) For NGINX Ingress Controller, see [https://kubernetes.github.io/ingress-nginx/user-guide/nginx-configuration/annotations/](https://kubernetes.github.io/ingress-nginx/user-guide/nginx-configuration/annotations/) For Traefik Ingress Controller, see [https://doc.traefik.io/traefik/routing/providers/kubernetes-ingress/#annotations](https://doc.traefik.io/traefik/routing/providers/kubernetes-ingress/#annotations) |
| ingress.className | string | `""` | The className specifies the IngressClass object which is responsible for that class. Note for Kubernetes >= 1.18 it is required to have an existing IngressClass object. If IngressClass object does not exists, omit className and add the deprecated annotation 'kubernetes.io/ingress.class' instead. For Kubernetes < 1.18 either use className or annotation 'kubernetes.io/ingress.class'. See https://kubernetes.io/docs/concepts/services-networking/ingress/#ingress-class |
| ingress.enabled | bool | `false` | Whether to create ingress or not. Note: For ingress an Ingress Controller (e.g. AWS LB Controller, NGINX Ingress Controller, Traefik, ...) is required and service.type should be ClusterIP or NodePort depending on your configuration |
| ingress.hosts[0].host | string | `"epi.some-pharma-company.com"` | The FQDN/hostname |
| ingress.hosts[0].paths[0].path | string | `"/"` | The Ingress Path. See [https://kubernetes.io/docs/concepts/services-networking/ingress/#examples](https://kubernetes.io/docs/concepts/services-networking/ingress/#examples) Note: For Ingress Controllers like AWS LB Controller see their specific documentation. |
| ingress.hosts[0].paths[0].pathType | string | `"ImplementationSpecific"` | The type of path. This value is required since Kubernetes 1.18. For Ingress Controllers like AWS LB Controller or Traefik it is usually required to set its value to ImplementationSpecific See [https://kubernetes.io/docs/concepts/services-networking/ingress/#path-types](https://kubernetes.io/docs/concepts/services-networking/ingress/#path-types) and [https://kubernetes.io/blog/2020/04/02/improvements-to-the-ingress-api-in-kubernetes-1.18/](https://kubernetes.io/blog/2020/04/02/improvements-to-the-ingress-api-in-kubernetes-1.18/) |
| ingress.tls | list | `[]` |  |
| kubectl | object | `{"image":{"pullPolicy":"IfNotPresent","repository":"bitnami/kubectl","tag":"1.21.8"}}` | Settings for Container with kubectl installed used by Init and Cleanup Job |
| kubectl.image.pullPolicy | string | `"IfNotPresent"` | Image Pull Policy |
| kubectl.image.repository | string | `"bitnami/kubectl"` | The repository of the container image containing kubectl |
| kubectl.image.tag | string | `"1.21.8"` | The Tag of the image containing kubectl. Minor Version should match to your Kubernetes Cluster Version. |
| livenessProbe | object | `{"failureThreshold":3,"httpGet":{"path":"/","port":"http"},"initialDelaySeconds":10,"periodSeconds":10,"successThreshold":1,"timeoutSeconds":1}` | Liveness probe. See [https://kubernetes.io/docs/tasks/configure-pod-container/configure-liveness-readiness-startup-probes/](https://kubernetes.io/docs/tasks/configure-pod-container/configure-liveness-readiness-startup-probes/) |
| nameOverride | string | `""` | nameOverride replaces the name of the chart in the Chart.yaml file, when this is used to construct Kubernetes object names. From [https://stackoverflow.com/questions/63838705/what-is-the-difference-between-fullnameoverride-and-nameoverride-in-helm](https://stackoverflow.com/questions/63838705/what-is-the-difference-between-fullnameoverride-and-nameoverride-in-helm) |
| nodeSelector | object | `{}` | Node Selectors in order to assign pods to certain nodes. See [https://kubernetes.io/docs/concepts/scheduling-eviction/assign-pod-node/](https://kubernetes.io/docs/concepts/scheduling-eviction/assign-pod-node/) |
| persistence | object | `{"accessModes":["ReadWriteOnce"],"deletePvcOnUninstall":true,"finalizers":["kubernetes.io/pvc-protection"],"size":"20Gi","storageClassName":""}` | Enable persistence using Persistent Volume Claims See [http://kubernetes.io/docs/user-guide/persistent-volumes/](http://kubernetes.io/docs/user-guide/persistent-volumes/) |
| persistence.deletePvcOnUninstall | bool | `true` | Boolean flag whether to delete the persistent volume on uninstall or not. |
| persistence.size | string | `"20Gi"` | Size of the volume |
| persistence.storageClassName | string | `""` | Name of the storage class. If empty or not set then storage class will not be set - which means that the default storage class will be used. |
| podAnnotations | object | `{}` | Annotations added to the pod |
| podSecurityContext | object | `{}` | Security Context for the pod.  IMPORTANT: Take a look at values.yaml file for configuration for non-root user! See [https://kubernetes.io/docs/tasks/configure-pod-container/security-context/#set-the-security-context-for-a-pod](https://kubernetes.io/docs/tasks/configure-pod-container/security-context/#set-the-security-context-for-a-pod) For running as root-user (which is not recommendedIf you run as root user (which is absolutely NOT recommended) then  |
| readinessProbe | object | `{"exec":{"command":["cat","/ePI-workspace/apihub-root/ready"]},"failureThreshold":60,"initialDelaySeconds":30,"periodSeconds":5,"successThreshold":1}` | Readiness probe. See [https://kubernetes.io/docs/tasks/configure-pod-container/configure-liveness-readiness-startup-probes/](https://kubernetes.io/docs/tasks/configure-pod-container/configure-liveness-readiness-startup-probes/) |
| replicaCount | int | `1` | The number of replicas if autoscaling is false |
| resources | object | `{}` | Resource constraints for the container |
| securityContext | object | `{}` | Security Context for the application container IMPORTANT: Take a look at values.yaml file for configuration for non-root user! See [https://kubernetes.io/docs/tasks/configure-pod-container/security-context/#set-the-security-context-for-a-container](https://kubernetes.io/docs/tasks/configure-pod-container/security-context/#set-the-security-context-for-a-container)  For running as non-root with uid 1000, remove {} from next line and uncomment next lines! |
| service.annotations | object | `{}` | Annotations for the service. See AWS, see [https://kubernetes.io/docs/concepts/services-networking/service/#ssl-support-on-aws](https://kubernetes.io/docs/concepts/services-networking/service/#ssl-support-on-aws) For Azure, see [https://kubernetes-sigs.github.io/cloud-provider-azure/topics/loadbalancer/#loadbalancer-annotations](https://kubernetes-sigs.github.io/cloud-provider-azure/topics/loadbalancer/#loadbalancer-annotations) |
| service.port | int | `80` | Port where the service will be exposed |
| service.type | string | `"ClusterIP"` | Either ClusterIP, NodePort or LoadBalancer. See [https://kubernetes.io/docs/concepts/services-networking/service/](https://kubernetes.io/docs/concepts/services-networking/service/) |
| serviceAccount.annotations | object | `{}` | Annotations to add to the service account |
| serviceAccount.create | bool | `false` | Specifies whether a service account should be created |
| serviceAccount.name | string | `""` | The name of the service account to use. If not set and create is true, a name is generated using the fullname template |
| tolerations | list | `[]` | Tolerations for scheduling a pod. See [https://kubernetes.io/docs/concepts/scheduling-eviction/taint-and-toleration/](https://kubernetes.io/docs/concepts/scheduling-eviction/taint-and-toleration/) |

----------------------------------------------
Autogenerated from chart metadata using [helm-docs v1.5.0](https://github.com/norwoodj/helm-docs/releases/v1.5.0)
