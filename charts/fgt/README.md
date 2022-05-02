# fgt

![Version: 0.1.2](https://img.shields.io/badge/Version-0.1.2-informational?style=flat-square) ![Type: application](https://img.shields.io/badge/Type-application-informational?style=flat-square) ![AppVersion: latest](https://img.shields.io/badge/AppVersion-latest-informational?style=flat-square)

A Helm chart for a FGT deployment on Kubernetes

## Requirements

- [helm 3](https://helm.sh/docs/intro/install/)
- These mandatory configuration values:
  - Domain - The Domain - e.g. `fgt`
  - Sub Domain - The Sub Domain - e.g. `fgt.my-company`
  - Vault Domain - The Vault Domain - e.g. `vault.my-company`
  - ethadapterUrl - The Full URL of the Ethadapter including protocol and port -  e.g. "https://ethadapter.my-company.com:3000"
  - bdnsHosts - The Centrally managed and provided BDNS Hosts Config -

## Usage

- [Here](./README.md#values) is a full list of all configuration values.
- The [values.yaml file](./values.yaml) shows the raw view of all configuration values.

## Changelog

- Initial version 0.1.0
  - For use with fgt v0.9.2

## Helm Lifecycle and Kubernetes Resources Lifetime

This helm chart uses Helm [hooks](https://helm.sh/docs/topics/charts_hooks/) in order to install, upgrade and manage the application and its resources.

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
    helm upgrade my-release-name pharmaledger-imi/fgt --version=0.1.2 \
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
    helm upgrade my-release-name pharmaledger-imi/fgt --version=0.1.2 \
        --install \
        --namespace=my-namespace \
        --values my-config.yaml \
    ```

2. Wait until installation has finished successfully and the deployment is up and running.

    Provide the `--wait` argument and time to wait (default is 5 minutes) via `--timeout`

    ```bash
    helm upgrade my-release-name pharmaledger-imi/fgt --version=0.1.2 \
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

## Values

| Key | Type | Default | Description |
|-----|------|---------|-------------|
| affinity | object | `{}` | Affinity for scheduling a pod. See [https://kubernetes.io/docs/concepts/scheduling-eviction/assign-pod-node/](https://kubernetes.io/docs/concepts/scheduling-eviction/assign-pod-node/) |
| config | object | `{"apihub":"{\n  \"storage\": \"../apihub-root\",\n  \"port\": 8080,\n  \"preventRateLimit\": true,\n  \"activeComponents\": [\n    \"virtualMQ\",\n    \"messaging\",\n    \"notifications\",\n    \"filesManager\",\n    \"bdns\",\n    \"bricksLedger\",\n    \"bricksFabric\",\n    \"bricking\",\n    \"anchoring\",\n    \"dsu-wizard\",\n    \"pdm-dsu-toolkit-app-store\",\n    \"pdm-dsu-toolkit-app-commands\",\n    \"fgt-dsu-wizard\",\n    \"gtin-dsu-wizard\",\n    \"mq\",\n    \"staticServer\"\n  ],\n  \"componentsConfig\": {\n    \"gtin-dsu-wizard\": {\n      \"module\": \"./../../gtin-dsu-wizard\"\n    },\n    \"pdm-dsu-toolkit-app-commands\": {\n      \"module\": \"./../../pdm-dsu-toolkit\",\n      \"function\": \"Init\"\n    },\n    \"fgt-dsu-wizard\": {\n      \"module\": \"./../../fgt-dsu-wizard\",\n      \"function\": \"Init\"\n    },\n    \"mq\":{\n      \"module\": \"./components/mqHub\",\n      \"function\": \"MQHub\"\n    },\n    \"bricking\": {},\n    \"anchoring\": {}\n  },\n  \"CORS\": {\n    \"Access-Control-Allow-Origin\":\"*\",\n    \"Access-Control-Allow-Methods\": \"POST, GET, PUT, DELETE, OPTIONS\",\n    \"Access-Control-Allow-Credentials\": true\n  },\n  \"enableRequestLogger\": true,\n  \"enableJWTAuthorisation\": false,\n  \"enableLocalhostAuthorization\": false,\n  \"skipJWTAuthorisation\": [\n    \"/assets\",\n    \"/leaflet-wallet\",\n    \"/dsu-fabric-wallet\",\n    \"/directory-summary\",\n    \"/resources\",\n    \"/bdns\",\n    \"/anchor/fgt\",\n    \"/anchor/default\",\n    \"/anchor/vault\",\n    \"/bricking\",\n    \"/bricksFabric\",\n    \"/bricksledger\",\n    \"/create-channel\",\n    \"/forward-zeromq\",\n    \"/send-message\",\n    \"/receive-message\",\n    \"/files\",\n    \"/notifications\",\n    \"/mq\"\n  ]\n}","bdnsHosts":"{\n  \"default\": {\n    \"replicas\": [],\n    \"brickStorages\": [\n      \"$ORIGIN\"\n    ],\n    \"anchoringServices\": [\n      \"$ORIGIN\"\n    ]\n  },\n  \"traceability\": {\n    \"replicas\": [],\n    \"brickStorages\": [\n      \"$ORIGIN\"\n    ],\n    \"mqEndpoints\": [\n      \"$ORIGIN\"\n    ],\n    \"anchoringServices\": [\n      \"$ORIGIN\"\n    ]\n  },\n  \"vault\": {\n    \"replicas\": [],\n    \"brickStorages\": [\n      \"$ORIGIN\"\n    ],\n    \"anchoringServices\": [\n      \"$ORIGIN\"\n    ]\n  }\n}","credentials":"{\n  \"id\": {\n    \"secret\": \"MAH251339219\",\n    \"public\": true\n  },\n  \"name\": {\n    \"secret\": \"Company Inc.\",\n    \"public\": true\n  },\n  \"email\": {\n    \"secret\": \"pharmaledger@company.com\",\n    \"public\": true\n  },\n  \"pass\": {\n    \"secret\": \"This1sSuchAS3curePassw0rd\"\n  }\n}","domain":"fgt","ethadapterUrl":"","fgtApi":"http://fgt-api.some-pharma-company.com/traceability","role":"mah","sleepTime":"10s","subDomain":"fgt.my-company","vaultDomain":"vault.my-company"}` | Configuration. Will be put in ConfigMaps. |
| config.apihub | string | `"{\n  \"storage\": \"../apihub-root\",\n  \"port\": 8080,\n  \"preventRateLimit\": true,\n  \"activeComponents\": [\n    \"virtualMQ\",\n    \"messaging\",\n    \"notifications\",\n    \"filesManager\",\n    \"bdns\",\n    \"bricksLedger\",\n    \"bricksFabric\",\n    \"bricking\",\n    \"anchoring\",\n    \"dsu-wizard\",\n    \"pdm-dsu-toolkit-app-store\",\n    \"pdm-dsu-toolkit-app-commands\",\n    \"fgt-dsu-wizard\",\n    \"gtin-dsu-wizard\",\n    \"mq\",\n    \"staticServer\"\n  ],\n  \"componentsConfig\": {\n    \"gtin-dsu-wizard\": {\n      \"module\": \"./../../gtin-dsu-wizard\"\n    },\n    \"pdm-dsu-toolkit-app-commands\": {\n      \"module\": \"./../../pdm-dsu-toolkit\",\n      \"function\": \"Init\"\n    },\n    \"fgt-dsu-wizard\": {\n      \"module\": \"./../../fgt-dsu-wizard\",\n      \"function\": \"Init\"\n    },\n    \"mq\":{\n      \"module\": \"./components/mqHub\",\n      \"function\": \"MQHub\"\n    },\n    \"bricking\": {},\n    \"anchoring\": {}\n  },\n  \"CORS\": {\n    \"Access-Control-Allow-Origin\":\"*\",\n    \"Access-Control-Allow-Methods\": \"POST, GET, PUT, DELETE, OPTIONS\",\n    \"Access-Control-Allow-Credentials\": true\n  },\n  \"enableRequestLogger\": true,\n  \"enableJWTAuthorisation\": false,\n  \"enableLocalhostAuthorization\": false,\n  \"skipJWTAuthorisation\": [\n    \"/assets\",\n    \"/leaflet-wallet\",\n    \"/dsu-fabric-wallet\",\n    \"/directory-summary\",\n    \"/resources\",\n    \"/bdns\",\n    \"/anchor/fgt\",\n    \"/anchor/default\",\n    \"/anchor/vault\",\n    \"/bricking\",\n    \"/bricksFabric\",\n    \"/bricksledger\",\n    \"/create-channel\",\n    \"/forward-zeromq\",\n    \"/send-message\",\n    \"/receive-message\",\n    \"/files\",\n    \"/notifications\",\n    \"/mq\"\n  ]\n}"` | Configuration file apihub.json. Settings: [https://docs.google.com/document/d/1mg35bb1UBUmTpL1Kt4GuZ7P0K_FMqt2Mb8B3iaDf52I/edit#heading=h.z84gh8sclah3](https://docs.google.com/document/d/1mg35bb1UBUmTpL1Kt4GuZ7P0K_FMqt2Mb8B3iaDf52I/edit#heading=h.z84gh8sclah3) |
| config.bdnsHosts | string | `"{\n  \"default\": {\n    \"replicas\": [],\n    \"brickStorages\": [\n      \"$ORIGIN\"\n    ],\n    \"anchoringServices\": [\n      \"$ORIGIN\"\n    ]\n  },\n  \"traceability\": {\n    \"replicas\": [],\n    \"brickStorages\": [\n      \"$ORIGIN\"\n    ],\n    \"mqEndpoints\": [\n      \"$ORIGIN\"\n    ],\n    \"anchoringServices\": [\n      \"$ORIGIN\"\n    ]\n  },\n  \"vault\": {\n    \"replicas\": [],\n    \"brickStorages\": [\n      \"$ORIGIN\"\n    ],\n    \"anchoringServices\": [\n      \"$ORIGIN\"\n    ]\n  }\n}"` | Centrally managed and provided BDNS Hosts Config |
| config.domain | string | `"fgt"` | The Domain, e.g. "epipoc" |
| config.ethadapterUrl | string | `""` | The Full URL of the Ethadapter including protocol and port, e.g. "https://ethadapter.my-company.com:3000" |
| config.fgtApi | string | `"http://fgt-api.some-pharma-company.com/traceability"` | The URL of the FGT API including port |
| config.role | string | `"mah"` | The role the FGT API Hub takes |
| config.subDomain | string | `"fgt.my-company"` | The Subdomain, should be domain.company, e.g. epipoc.my-company |
| config.vaultDomain | string | `"vault.my-company"` | The Vault domain, should be vault.company, e.g. vault.my-company |
| deploymentStrategy.type | string | `"Recreate"` |  |
| fullnameOverride | string | `""` | fullnameOverride completely replaces the generated name. From [https://stackoverflow.com/questions/63838705/what-is-the-difference-between-fullnameoverride-and-nameoverride-in-helm](https://stackoverflow.com/questions/63838705/what-is-the-difference-between-fullnameoverride-and-nameoverride-in-helm) |
| image.pullPolicy | string | `"IfNotPresent"` | Image Pull Policy |
| image.repository | string | `"fgt-workspace"` | The repository of the container image |
| image.sha | string | `""` | sha256 digest of the image. Do not add the prefix "@sha256:" |
| image.tag | string | `""` |  |
| imagePullSecrets | list | `[]` | Secret(s) for pulling an container image from a private registry. See [https://kubernetes.io/docs/tasks/configure-pod-container/pull-image-private-registry/](https://kubernetes.io/docs/tasks/configure-pod-container/pull-image-private-registry/) |
| ingress.api.annotations | object | `{}` | Ingress annotations. For AWS LB Controller, see [https://kubernetes-sigs.github.io/aws-load-balancer-controller/v2.3/guide/ingress/annotations/](https://kubernetes-sigs.github.io/aws-load-balancer-controller/v2.3/guide/ingress/annotations/) For Azure Application Gateway Ingress Controller, see [https://azure.github.io/application-gateway-kubernetes-ingress/annotations/](https://azure.github.io/application-gateway-kubernetes-ingress/annotations/) For NGINX Ingress Controller, see [https://kubernetes.github.io/ingress-nginx/user-guide/nginx-configuration/annotations/](https://kubernetes.github.io/ingress-nginx/user-guide/nginx-configuration/annotations/) For Traefik Ingress Controller, see [https://doc.traefik.io/traefik/routing/providers/kubernetes-ingress/#annotations](https://doc.traefik.io/traefik/routing/providers/kubernetes-ingress/#annotations) |
| ingress.api.className | string | `""` | The className specifies the IngressClass object which is responsible for that class. Note for Kubernetes >= 1.18 it is required to have an existing IngressClass object. If IngressClass object does not exists, omit className and add the deprecated annotation 'kubernetes.io/ingress.class' instead. For Kubernetes < 1.18 either use className or annotation 'kubernetes.io/ingress.class'. See https://kubernetes.io/docs/concepts/services-networking/ingress/#ingress-class |
| ingress.api.enabled | bool | `false` | Whether to create ingress or not. Note: For ingress an Ingress Controller (e.g. AWS LB Controller, NGINX Ingress Controller, Traefik, ...) is required and service.type should be ClusterIP or NodePort depending on your configuration |
| ingress.api.hosts | list | `[{"host":"fgt-api.some-pharma-company.com","paths":[{"path":"/","pathType":"ImplementationSpecific"}]}]` | A list of hostnames and path(s) to listen at the Ingress Controller |
| ingress.api.hosts[0].host | string | `"fgt-api.some-pharma-company.com"` | The FQDN/hostname |
| ingress.api.hosts[0].paths[0].path | string | `"/"` | The Ingress Path. See [https://kubernetes.io/docs/concepts/services-networking/ingress/#examples](https://kubernetes.io/docs/concepts/services-networking/ingress/#examples) Note: For Ingress Controllers like AWS LB Controller see their specific documentation. |
| ingress.api.hosts[0].paths[0].pathType | string | `"ImplementationSpecific"` | The type of path. This value is required since Kubernetes 1.18. For Ingress Controllers like AWS LB Controller or Traefik it is usually required to set its value to ImplementationSpecific See [https://kubernetes.io/docs/concepts/services-networking/ingress/#path-types](https://kubernetes.io/docs/concepts/services-networking/ingress/#path-types) and [https://kubernetes.io/blog/2020/04/02/improvements-to-the-ingress-api-in-kubernetes-1.18/](https://kubernetes.io/blog/2020/04/02/improvements-to-the-ingress-api-in-kubernetes-1.18/) |
| ingress.api.tls | list | `[]` |  |
| ingress.app.annotations | object | `{}` | Ingress annotations. For AWS LB Controller, see [https://kubernetes-sigs.github.io/aws-load-balancer-controller/v2.3/guide/ingress/annotations/](https://kubernetes-sigs.github.io/aws-load-balancer-controller/v2.3/guide/ingress/annotations/) For Azure Application Gateway Ingress Controller, see [https://azure.github.io/application-gateway-kubernetes-ingress/annotations/](https://azure.github.io/application-gateway-kubernetes-ingress/annotations/) For NGINX Ingress Controller, see [https://kubernetes.github.io/ingress-nginx/user-guide/nginx-configuration/annotations/](https://kubernetes.github.io/ingress-nginx/user-guide/nginx-configuration/annotations/) For Traefik Ingress Controller, see [https://doc.traefik.io/traefik/routing/providers/kubernetes-ingress/#annotations](https://doc.traefik.io/traefik/routing/providers/kubernetes-ingress/#annotations) |
| ingress.app.className | string | `""` | The className specifies the IngressClass object which is responsible for that class. Note for Kubernetes >= 1.18 it is required to have an existing IngressClass object. If IngressClass object does not exists, omit className and add the deprecated annotation 'kubernetes.io/ingress.class' instead. For Kubernetes < 1.18 either use className or annotation 'kubernetes.io/ingress.class'. See https://kubernetes.io/docs/concepts/services-networking/ingress/#ingress-class |
| ingress.app.enabled | bool | `false` | Whether to create ingress or not. Note: For ingress an Ingress Controller (e.g. AWS LB Controller, NGINX Ingress Controller, Traefik, ...) is required and service.type should be ClusterIP or NodePort depending on your configuration |
| ingress.app.hosts | list | `[{"host":"fgt.some-pharma-company.com","paths":[{"path":"/","pathType":"ImplementationSpecific"}]}]` | A list of hostnames and path(s) to listen at the Ingress Controller |
| ingress.app.hosts[0].host | string | `"fgt.some-pharma-company.com"` | The FQDN/hostname |
| ingress.app.hosts[0].paths[0].path | string | `"/"` | The Ingress Path. See [https://kubernetes.io/docs/concepts/services-networking/ingress/#examples](https://kubernetes.io/docs/concepts/services-networking/ingress/#examples) Note: For Ingress Controllers like AWS LB Controller see their specific documentation. |
| ingress.app.hosts[0].paths[0].pathType | string | `"ImplementationSpecific"` | The type of path. This value is required since Kubernetes 1.18. For Ingress Controllers like AWS LB Controller or Traefik it is usually required to set its value to ImplementationSpecific See [https://kubernetes.io/docs/concepts/services-networking/ingress/#path-types](https://kubernetes.io/docs/concepts/services-networking/ingress/#path-types) and [https://kubernetes.io/blog/2020/04/02/improvements-to-the-ingress-api-in-kubernetes-1.18/](https://kubernetes.io/blog/2020/04/02/improvements-to-the-ingress-api-in-kubernetes-1.18/) |
| ingress.app.tls | list | `[]` |  |
| ingress.swagger.annotations | object | `{}` | Ingress annotations. For AWS LB Controller, see [https://kubernetes-sigs.github.io/aws-load-balancer-controller/v2.3/guide/ingress/annotations/](https://kubernetes-sigs.github.io/aws-load-balancer-controller/v2.3/guide/ingress/annotations/) For Azure Application Gateway Ingress Controller, see [https://azure.github.io/application-gateway-kubernetes-ingress/annotations/](https://azure.github.io/application-gateway-kubernetes-ingress/annotations/) For NGINX Ingress Controller, see [https://kubernetes.github.io/ingress-nginx/user-guide/nginx-configuration/annotations/](https://kubernetes.github.io/ingress-nginx/user-guide/nginx-configuration/annotations/) For Traefik Ingress Controller, see [https://doc.traefik.io/traefik/routing/providers/kubernetes-ingress/#annotations](https://doc.traefik.io/traefik/routing/providers/kubernetes-ingress/#annotations) |
| ingress.swagger.className | string | `""` | The className specifies the IngressClass object which is responsible for that class. Note for Kubernetes >= 1.18 it is required to have an existing IngressClass object. If IngressClass object does not exists, omit className and add the deprecated annotation 'kubernetes.io/ingress.class' instead. For Kubernetes < 1.18 either use className or annotation 'kubernetes.io/ingress.class'. See https://kubernetes.io/docs/concepts/services-networking/ingress/#ingress-class |
| ingress.swagger.enabled | bool | `false` | Whether to create ingress or not. Note: For ingress an Ingress Controller (e.g. AWS LB Controller, NGINX Ingress Controller, Traefik, ...) is required and service.type should be ClusterIP or NodePort depending on your configuration |
| ingress.swagger.hosts | list | `[{"host":"fgt-swagger.some-pharma-company.com","paths":[{"path":"/","pathType":"ImplementationSpecific"}]}]` | A list of hostnames and path(s) to listen at the Ingress Controller |
| ingress.swagger.hosts[0].host | string | `"fgt-swagger.some-pharma-company.com"` | The FQDN/hostname |
| ingress.swagger.hosts[0].paths[0].path | string | `"/"` | The Ingress Path. See [https://kubernetes.io/docs/concepts/services-networking/ingress/#examples](https://kubernetes.io/docs/concepts/services-networking/ingress/#examples) Note: For Ingress Controllers like AWS LB Controller see their specific documentation. |
| ingress.swagger.hosts[0].paths[0].pathType | string | `"ImplementationSpecific"` | The type of path. This value is required since Kubernetes 1.18. For Ingress Controllers like AWS LB Controller or Traefik it is usually required to set its value to ImplementationSpecific See [https://kubernetes.io/docs/concepts/services-networking/ingress/#path-types](https://kubernetes.io/docs/concepts/services-networking/ingress/#path-types) and [https://kubernetes.io/blog/2020/04/02/improvements-to-the-ingress-api-in-kubernetes-1.18/](https://kubernetes.io/blog/2020/04/02/improvements-to-the-ingress-api-in-kubernetes-1.18/) |
| ingress.swagger.tls | list | `[]` |  |
| livenessProbe | object | `{"failureThreshold":20,"httpGet":{"path":"/","port":"app"},"initialDelaySeconds":10,"periodSeconds":10,"successThreshold":1,"timeoutSeconds":1}` | Liveness probe. See [https://kubernetes.io/docs/tasks/configure-pod-container/configure-liveness-readiness-startup-probes/](https://kubernetes.io/docs/tasks/configure-pod-container/configure-liveness-readiness-startup-probes/) |
| nameOverride | string | `""` | nameOverride replaces the name of the chart in the Chart.yaml file, when this is used to construct Kubernetes object names. From [https://stackoverflow.com/questions/63838705/what-is-the-difference-between-fullnameoverride-and-nameoverride-in-helm](https://stackoverflow.com/questions/63838705/what-is-the-difference-between-fullnameoverride-and-nameoverride-in-helm) |
| nodeSelector | object | `{}` | Node Selectors in order to assign pods to certain nodes. See [https://kubernetes.io/docs/concepts/scheduling-eviction/assign-pod-node/](https://kubernetes.io/docs/concepts/scheduling-eviction/assign-pod-node/) |
| persistence | object | `{"accessModes":["ReadWriteOnce"],"deletePvcOnUninstall":true,"finalizers":["kubernetes.io/pvc-protection"],"size":"20Gi","storageClassName":""}` | Enable persistence using Persistent Volume Claims See [http://kubernetes.io/docs/user-guide/persistent-volumes/](http://kubernetes.io/docs/user-guide/persistent-volumes/) |
| persistence.deletePvcOnUninstall | bool | `true` | Boolean flag whether to delete the persistent volume on uninstall or not. |
| persistence.size | string | `"20Gi"` | Size of the volume |
| persistence.storageClassName | string | `""` | Name of the storage class. If empty or not set then storage class will not be set - which means that the default storage class will be used. |
| podAnnotations | object | `{}` | Annotations added to the pod |
| podSecurityContext | object | `{}` | Security Context for the pod.  IMPORTANT: Take a look at values.yaml file for configuration for non-root user! See [https://kubernetes.io/docs/tasks/configure-pod-container/security-context/#set-the-security-context-for-a-pod](https://kubernetes.io/docs/tasks/configure-pod-container/security-context/#set-the-security-context-for-a-pod) For running as root-user (which is not recommendedIf you run as root user (which is absolutely NOT recommended) then  |
| readinessProbe | object | `{"exec":{"command":["cat","/fgt-workspace/apihub-root/ready"]},"failureThreshold":60,"initialDelaySeconds":500,"periodSeconds":5,"successThreshold":1}` | Readiness probe. See [https://kubernetes.io/docs/tasks/configure-pod-container/configure-liveness-readiness-startup-probes/](https://kubernetes.io/docs/tasks/configure-pod-container/configure-liveness-readiness-startup-probes/) |
| replicaCount | int | `1` |  |
| resources | object | `{}` | Resource constraints for the container |
| securityContext | object | `{}` | Security Context for the application container IMPORTANT: Take a look at values.yaml file for configuration for non-root user! See [https://kubernetes.io/docs/tasks/configure-pod-container/security-context/#set-the-security-context-for-a-container](https://kubernetes.io/docs/tasks/configure-pod-container/security-context/#set-the-security-context-for-a-container)  For running as non-root with uid 1000, remove {} from next line and uncomment next lines! |
| serviceAccount.annotations | object | `{}` |  |
| serviceAccount.automountServiceAccountToken | bool | `false` | Whether automounting API credentials for a service account is enabled or not. See [https://docs.bridgecrew.io/docs/bc_k8s_35](https://docs.bridgecrew.io/docs/bc_k8s_35) |
| serviceAccount.create | bool | `false` |  |
| serviceAccount.name | string | `""` |  |
| services.api.annotations | object | `{}` | Annotations for the service. See AWS, see [https://kubernetes.io/docs/concepts/services-networking/service/#ssl-support-on-aws](https://kubernetes.io/docs/concepts/services-networking/service/#ssl-support-on-aws) For Azure, see [https://kubernetes-sigs.github.io/cloud-provider-azure/topics/loadbalancer/#loadbalancer-annotations](https://kubernetes-sigs.github.io/cloud-provider-azure/topics/loadbalancer/#loadbalancer-annotations) |
| services.api.port | int | `80` | Port where the service will be exposed |
| services.api.type | string | `"ClusterIP"` | Either ClusterIP, NodePort or LoadBalancer. See [https://kubernetes.io/docs/concepts/services-networking/service/](https://kubernetes.io/docs/concepts/services-networking/service/) |
| services.app.annotations | object | `{}` | Annotations for the service. See AWS, see [https://kubernetes.io/docs/concepts/services-networking/service/#ssl-support-on-aws](https://kubernetes.io/docs/concepts/services-networking/service/#ssl-support-on-aws) For Azure, see [https://kubernetes-sigs.github.io/cloud-provider-azure/topics/loadbalancer/#loadbalancer-annotations](https://kubernetes-sigs.github.io/cloud-provider-azure/topics/loadbalancer/#loadbalancer-annotations) |
| services.app.port | int | `80` | Port where the service will be exposed |
| services.app.type | string | `"ClusterIP"` | Either ClusterIP, NodePort or LoadBalancer. See [https://kubernetes.io/docs/concepts/services-networking/service/](https://kubernetes.io/docs/concepts/services-networking/service/) |
| services.swagger.annotations | object | `{}` | Annotations for the service. See AWS, see [https://kubernetes.io/docs/concepts/services-networking/service/#ssl-support-on-aws](https://kubernetes.io/docs/concepts/services-networking/service/#ssl-support-on-aws) For Azure, see [https://kubernetes-sigs.github.io/cloud-provider-azure/topics/loadbalancer/#loadbalancer-annotations](https://kubernetes-sigs.github.io/cloud-provider-azure/topics/loadbalancer/#loadbalancer-annotations) |
| services.swagger.port | int | `80` | Port where the service will be exposed |
| services.swagger.type | string | `"ClusterIP"` | Either ClusterIP, NodePort or LoadBalancer. See [https://kubernetes.io/docs/concepts/services-networking/service/](https://kubernetes.io/docs/concepts/services-networking/service/) |
| tolerations | list | `[]` | Tolerations for scheduling a pod. See [https://kubernetes.io/docs/concepts/scheduling-eviction/taint-and-toleration/](https://kubernetes.io/docs/concepts/scheduling-eviction/taint-and-toleration/) |

----------------------------------------------
Autogenerated from chart metadata using [helm-docs v1.8.1](https://github.com/norwoodj/helm-docs/releases/v1.8.1)