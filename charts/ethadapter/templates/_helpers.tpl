{{/*
Expand the name of the chart.
*/}}
{{- define "ethadapter.name" -}}
{{- default .Chart.Name .Values.nameOverride | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Create a default fully qualified app name.
We truncate at 63 chars because some Kubernetes name fields are limited to this (by the DNS naming spec).
If release name contains chart name it will be used as a full name.
*/}}
{{- define "ethadapter.fullname" -}}
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
{{- define "ethadapter.chart" -}}
{{- printf "%s-%s" .Chart.Name .Chart.Version | replace "+" "_" | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Common labels
*/}}
{{- define "ethadapter.labels" -}}
helm.sh/chart: {{ include "ethadapter.chart" . }}
{{ include "ethadapter.selectorLabels" . }}
{{- if .Chart.AppVersion }}
app.kubernetes.io/version: {{ .Chart.AppVersion | quote }}
{{- end }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
{{- end }}

{{/*
Selector labels
*/}}
{{- define "ethadapter.selectorLabels" -}}
app.kubernetes.io/name: {{ include "ethadapter.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
{{- end }}

{{/*
Create the name of the service account to use
*/}}
{{- define "ethadapter.serviceAccountName" -}}
{{- if .Values.serviceAccount.create }}
{{- default (include "ethadapter.fullname" .) .Values.serviceAccount.name }}
{{- else }}
{{- default "default" .Values.serviceAccount.name }}
{{- end }}
{{- end }}



{{/*
The value for the Smart Contract Address
1. Look if value is explictly defined
2. If not, look if ConfigMap exists and get value from there
*/}}
{{- define "ethadapter.smartContractAddress" -}}
{{- if .Values.config.smartContractAddress }}
{{- .Values.config.smartContractAddress }}
{{- else }}
{{- $configMap := lookup "v1" "ConfigMap" .Release.Namespace .Values.config.smartContractConfigMapName -}}
{{- if $configMap -}}
{{- required "Either config.smartContractAddress must be set or value must exists in ConfigMap" (get $configMap.data .Values.config.smartContractConfigMapAddressKey) }}
{{- else -}}
{{- required "Either config.smartContractAddress must be set or ConfigMap with value must exists" "" }}
{{- end -}}
{{- end -}}
{{- end -}}


{{/*
The value for the Org JSON
*/}}
{{- define "ethadapter.orgAccountJson" -}}
{{- if .Values.secrets.orgAccountJson }}
{{- .Values.secrets.orgAccountJson }}
{{- else if .Values.secrets.orgAccountJsonBase64 }}
{{- .Values.secrets.orgAccountJsonBase64 | b64dec }}
{{- else }}
{{- required "Either secrets.orgAccountJson or secrets.orgAccountJsonBase64 must be set" "" }}
{{- end -}}
{{- end -}}
