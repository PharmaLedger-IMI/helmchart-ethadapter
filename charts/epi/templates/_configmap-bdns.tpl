{{- /*
Template for Configmap. Arguments to be passed are $ . suffix and an dictionary for annotations used for defining helm hooks.
See https://blog.flant.com/advanced-helm-templating/
*/}}
{{- define "epi.configmap-bdns" -}}
{{- $ := index . 0 }}
{{- $suffix := index . 2 }}
{{- $annotations := index . 3 }}
  {{- with index . 1 }}
apiVersion: v1
kind: ConfigMap
metadata:
  name: {{ include "epi.fullname" . }}-bdns{{ $suffix | default "" }}
  {{- with $annotations }}
  annotations:
    {{- toYaml . | nindent 4 }}
  {{- end }}
  labels:
    {{- include "epi.labels" . | nindent 4 }}
data:
  bdns.hosts: |-
{{ required "config.bdnsHosts must be set" .Values.config.bdnsHosts | indent 4 }}
{{- end }}
{{- end }}