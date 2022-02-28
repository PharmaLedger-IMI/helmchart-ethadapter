{{- /*
Template for Configmap. Arguments to be passed are $ . suffix and an dictionary for annotations used for defining helm hooks.
See https://blog.flant.com/advanced-helm-templating/
*/}}
{{- define "epi.configmap-config" -}}
{{- $ := index . 0 }}
{{- $suffix := index . 2 }}
{{- $annotations := index . 3 }}
{{- with index . 1 }}
apiVersion: v1
kind: ConfigMap
metadata:
  name: {{ include "epi.fullname" . }}-config{{ $suffix | default "" }}
  {{- with $annotations }}
  annotations:
    {{- toYaml . | nindent 4 }}
  {{- end }}
  labels:
    {{- include "epi.labels" . | nindent 4 }}
data:
  env.json: |
    {
      "PSK_TMP_WORKING_DIR": "tmp",
      "PSK_CONFIG_LOCATION": "../apihub-root/external-volume/config",
      "SSAPPS_FAVORITE_EDFS_ENDPOINT": "http://localhost:8080",
      "IS_PRODUCTION_BUILD": true,
      "VAULT_DOMAIN": {{ required "config.vaultDomain must be set" .Values.config.vaultDomain | quote}}
    }

  apihub.json: |-
    {
      "storage": "../apihub-root",
      "port": 8080,
      "preventRateLimit": true,
      "activeComponents": [
        "virtualMQ",
        "messaging",
        "notifications",
        "filesManager",
        "bdns",
        "bricksLedger",
        "bricksFabric",
        "bricking",
        "anchoring",
        "dsu-wizard",
        "gtin-dsu-wizard",
        "epi-mapping-engine",
        "epi-mapping-engine-results",
        "debugLogger",
        "mq",
        "staticServer"
      ],
      "componentsConfig": {
        "epi-mapping-engine": {
          "module": "./../../epi-utils",
          "function": "getEPIMappingEngineForAPIHUB"
        },
        "epi-mapping-engine-results": {
          "module": "./../../epi-utils",
          "function": "getEPIMappingEngineMessageResults"
        },
        "gtin-dsu-wizard": {
          "module": "./../../gtin-dsu-wizard"
        },
        "bricking": {},
        "anchoring": {}
      },
      "enableRequestLogger": true,
      "enableJWTAuthorisation": false,
      "enableLocalhostAuthorization": false,
      "skipJWTAuthorisation": [
        "/assets",
        "/leaflet-wallet",
        "/dsu-fabric-wallet",
        "/directory-summary",
        "/resources",
        "/bdns",
        "/anchor/epi",
        "/anchor/default",
        "/anchor/vault",
        "/bricking",
        "/bricksFabric",
        "/bricksledger",
        "/create-channel",
        "/forward-zeromq",
        "/send-message",
        "/receive-message",
        "/files",
        "/notifications",
        "/mq"
      ]
    }
{{- end }}
{{- end }}