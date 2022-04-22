{{- /*
Template for Configmap. Arguments to be passed are $ . suffix and an dictionary for annotations used for defining helm hooks.
See https://blog.flant.com/advanced-helm-templating/
*/}}
{{- define "fgt.configmap-config" -}}
{{- $ := index . 0 }}
{{- $suffix := index . 2 }}
{{- $annotations := index . 3 }}
{{- with index . 1 }}
apiVersion: v1
kind: ConfigMap
metadata:
  name: {{ include "fgt.fullname" . }}-config{{ $suffix | default "" }}
  {{- with $annotations }}
  annotations:
    {{- toYaml . | nindent 4 }}
  {{- end }}
  labels:
    {{- include "fgt.labels" . | nindent 4 }}
data:
  env.json: |
    {
      "PSK_TMP_WORKING_DIR": "tmp",
      "PSK_CONFIG_LOCATION": "../apihub-root/external-volume/config",
      "DEV": false
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
        "pdm-dsu-toolkit-app-store",
        "pdm-dsu-toolkit-app-commands",
        "fgt-dsu-wizard",
        "gtin-dsu-wizard",
        "mq",
        "staticServer"
      ],
      "componentsConfig": {
        "gtin-dsu-wizard": {
          "module": "./../../gtin-dsu-wizard"
        },
        "pdm-dsu-toolkit-app-commands": {
          "module": "./../../pdm-dsu-toolkit",
          "function": "Init"
        },
        "fgt-dsu-wizard": {
          "module": "./../../fgt-dsu-wizard",
          "function": "Init"
        },
        "mq":{
          "module": "./components/mqHub",
          "function": "MQHub"
        },
        "bricking": {},
        "anchoring": {}
      },
      "CORS": {
        "Access-Control-Allow-Origin":"*",
        "Access-Control-Allow-Methods": "POST, GET, PUT, DELETE, OPTIONS",
        "Access-Control-Allow-Credentials": true
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
        "/anchor/fgt",
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