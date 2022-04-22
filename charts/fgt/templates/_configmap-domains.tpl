{{- /*
Template for Configmap. Arguments to be passed are $ . suffix and an dictionary for annotations used for defining helm hooks.
See https://blog.flant.com/advanced-helm-templating/
*/}}
{{- define "fgt.configmap-domains" -}}
{{- $ := index . 0 }}
{{- $suffix := index . 2 }}
{{- $annotations := index . 3 }}
{{- with index . 1 }}
apiVersion: v1
kind: ConfigMap
metadata:
  name: {{ include "fgt.fullname" . }}-domains{{ $suffix | default "" }}
  {{- with $annotations }}
  annotations:
    {{- toYaml . | nindent 4 }}
  {{- end }}
  labels:
    {{- include "fgt.labels" . | nindent 4 }}
data:
  default.json: |-
    {
      "anchoring": {
        "type": "FS",
        "option": {
          "enableBricksLedger": false
        },
        "commands": {
          "addAnchor": "anchor"
        }
      }
    }

  predefined.json: |-
    {
      "anchoring": {
        "type": "FS",
        "option": {}
      }
    }

  traceability.json: |-
    {
      "anchoring": {
        "type": "FS",
        "option": {
          "enableBricksLedger": false
        },
        "commands": {
          "addAnchor": "anchor"
        }
      },
      "enable": ["mq"],
      "skipOAuth": [
        "/bricking/traceability/get-brick"
      ]
    }

  vault.json: |-
    {
      "anchoring": {
        "type": "FS",
        "option": {}
      }
    }
  
  {{ required "config.domain must be set" .Values.config.domain }}.json: |-
    {
      "anchoring": {
        "type": "ETH",
        "option": {
          "endpoint": {{ required "config.ethadapterUrl must be set" .Values.config.ethadapterUrl | quote }}
        }
      },
      "messagesEndpoint": "http://localhost:8080/mappingEngine/{{ required "config.domain must be set" .Values.config.domain }}/{{ required "config.subDomain must be set" .Values.config.subDomain }}/saveResult"
    }

  {{ required "config.subDomain must be set" .Values.config.subDomain }}.json: |-
    {
      "anchoring": {
        "type": "ETH",
        "option": {
          "endpoint": {{ required "config.ethadapterUrl must be set" .Values.config.ethadapterUrl | quote }}
        },
        "commands": {
            "addAnchor": "anchor"
        }
      }
    }

  {{ required "config.vaultDomain must be set" .Values.config.vaultDomain }}.json: |-
    {
      "anchoring": {
        "type": "FS",
         "option": {}
      }
    }

{{- end }}
{{- end }}