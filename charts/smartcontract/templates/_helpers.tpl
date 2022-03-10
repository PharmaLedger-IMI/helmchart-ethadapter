{{/*
Expand the name of the chart.
*/}}
{{- define "smartcontract.name" -}}
{{- default .Chart.Name .Values.nameOverride | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Create a default fully qualified app name.
We truncate at 63 chars because some Kubernetes name fields are limited to this (by the DNS naming spec).
If release name contains chart name it will be used as a full name.
*/}}
{{- define "smartcontract.fullname" -}}
{{- if .Values.fullnameOverride }}
{{- .Values.fullnameOverride | trunc 63 | trimSuffix "-" }}
{{- else }}
{{- $name := default .Chart.Name .Values.nameOverride }}
{{- if contains $name .Release.Name }}
{{- .Release.Name | trunc 63 | trimSuffix "-" }}
{{- else }}
{{- printf "%s-%s" .Release.Name $name | trunc 63 | trimSuffix "-" }}
{{- end }}
{{- end }}
{{- end }}

{{/*
Create chart name and version as used by the chart label.
*/}}
{{- define "smartcontract.chart" -}}
{{- printf "%s-%s" .Chart.Name .Chart.Version | replace "+" "_" | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Common labels
*/}}
{{- define "smartcontract.labels" -}}
helm.sh/chart: {{ include "smartcontract.chart" . }}
{{ include "smartcontract.selectorLabels" . }}
{{- if .Chart.AppVersion }}
app.kubernetes.io/version: {{ .Chart.AppVersion | quote }}
{{- end }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
{{- end }}

{{/*
Selector labels
*/}}
{{- define "smartcontract.selectorLabels" -}}
app.kubernetes.io/name: {{ include "smartcontract.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
{{- end }}

{{/*
Create the name of the service account to use
*/}}
{{- define "smartcontract.serviceAccountName" -}}
{{- if .Values.serviceAccount.create }}
{{- default (include "smartcontract.fullname" .) .Values.serviceAccount.name }}
{{- else }}
{{- default "default" .Values.serviceAccount.name }}
{{- end }}
{{- end }}

{{/*
The Name of the ConfigMap for the Anchoring SmartContract Data
*/}}
{{- define "smartcontract.configMapNameAnchoringInfo" -}}
{{- default (printf "%s-%s" (include "smartcontract.fullname" .) "anchoring-info") .Values.config.configMapAnchoringInfoName }}
{{- end }}

{{/*
Lookup potentially existing AnchoringSmartContract data
*/}}
{{- define "smartcontract.anchoringSmartContractData" -}}
{{- $configMap := lookup "v1" "ConfigMap" .Release.Namespace (include "smartcontract.configMapNameAnchoringInfo" .) -}}
{{- if $configMap -}}
{{/*
    Reusing existing data
*/}}
abi: |-
    {{ $configMap.data.abi | default "" }}
address: |-
    {{ $configMap.data.address | default "" }}
{{- else -}}
{{/*
    Use new data
*/}}
abi: ""
address: ""
{{- end -}}
{{- end -}}