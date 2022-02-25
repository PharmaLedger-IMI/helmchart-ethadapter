{{- /*
Template for Configmap. Arguments to be passed are $ . suffix and an dictionary for annotations used for defining helm hooks.
See https://blog.flant.com/advanced-helm-templating/
*/}}
{{- define "epi.configmap-environment" -}}
{{- $ := index . 0 }}
{{- $suffix := index . 2 }}
{{- $annotations := index . 3 }}
{{- with index . 1 }}
apiVersion: v1
kind: ConfigMap
metadata:
  name: {{ include "epi.fullname" . }}-environment{{ $suffix | default "" }}
  {{- with $annotations }}
  annotations:
    {{- toYaml . | nindent 4 }}
  {{- end }}
  labels:
    {{- include "epi.labels" . | nindent 4 }}
data:
  demiurge-environment.js: |-
    export default {
      "appName": "Demiurge",
      "vault": "server",
      "agent": "browser",
      "system":   "any",
      "browser":  "any",
      "mode":  "dev-secure",
      "vaultDomain":  {{ required "config.vaultDomain must be set" .Values.config.vaultDomain | quote}},
      "didDomain":  {{ required "config.vaultDomain must be set" .Values.config.vaultDomain | quote}},
      "enclaveType":"WalletDBEnclave",
      "sw": false,
      "pwa": false,
      "legenda for properties": " vault:(server, browser) agent:(mobile,  browser)  system:(iOS, Android, any) browser:(Chrome, Firefox, any) mode:(autologin,dev-autologin, secure, dev-secure) sw:(true, false) pwa:(true, false)"
    }
  dsu-explorer-environment.js: |-
    export default {
      "appName": "DSU Explorer",
      "vault": "server",
      "agent": "browser",
      "system":   "any",
      "browser":  "any",
      "mode":  "dev-autologin",
      "vaultDomain":  {{ required "config.vaultDomain must be set" .Values.config.vaultDomain | quote}},
      "didDomain":  {{ required "config.vaultDomain must be set" .Values.config.vaultDomain | quote}},
      "enclaveType": "WalletDBEnclave",
      "sw": true,
      "pwa": false,
      "allowPinLogin": false,
      "legenda for properties": " vault:(server, browser) agent:(mobile,  browser)  system:(iOS, Android, any) browser:(Chrome, Firefox, any) stage:(development, release) sw:(true, false) pwa:(true, false)"
    }
  dsu-fabric-environment.js: |-
    export default {
      "appName": "DSU_Fabric",
      "vault": "server",
      "agent": "browser",
      "system":   "any",
      "browser":  "any",
      "mode":  "dev-secure",
      "vaultDomain":  {{ required "config.vaultDomain must be set" .Values.config.vaultDomain | quote}},
      "didDomain":  {{ required "config.vaultDomain must be set" .Values.config.vaultDomain | quote}},
      "epiDomain":  {{ required "config.domain must be set" .Values.config.domain | quote}},
      "epiSubdomain":  {{ required "config.subDomain must be set" .Values.config.subDomain | quote}},
      "enclaveType": "WalletDBEnclave",
      "sw": false,
      "pwa": false,
      "allowPinLogin": false,
      "legenda for properties": " vault:(server, browser) agent:(mobile,  browser)  system:(iOS, Android, any) browser:(Chrome, Firefox, any) mode:(autologin,dev-autologin, secure, dev-secure) sw:(true, false) pwa:(true, false)"
    }

  leaflet-environment.js: |-
    export default  {
      "appName": "eLeaflet",
      "vault": "server",
      "agent": "browser",
      "system":   "any",
      "browser":  "any",
      "mode":  "autologin",
      "vaultDomain":  {{ required "config.vaultDomain must be set" .Values.config.vaultDomain | quote}},
      "didDomain":  {{ required "config.vaultDomain must be set" .Values.config.vaultDomain | quote}},
      "enclaveType": "WalletDBEnclave",
      "sw": false,
      "pwa": false,
      "allowPinLogin": false,
      "legenda for properties": " vault:(server, browser) agent:(mobile,  browser)  system:(iOS, Android, any) browser:(Chrome, Firefox, any) mode:(development, release) sw:(true, false) pwa:(true, false)"
    }

{{- end }}
{{- end }}