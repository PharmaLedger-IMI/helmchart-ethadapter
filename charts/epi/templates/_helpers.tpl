{{/*
Expand the name of the chart.
*/}}
{{- define "epi.name" -}}
{{- default .Chart.Name .Values.nameOverride | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Create a default fully qualified app name.
We truncate at 63 chars because some Kubernetes name fields are limited to this (by the DNS naming spec).
If release name contains chart name it will be used as a full name.
*/}}
{{- define "epi.fullname" -}}
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
{{- define "epi.chart" -}}
{{- printf "%s-%s" .Chart.Name .Chart.Version | replace "+" "_" | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Common labels
*/}}
{{- define "epi.labels" -}}
helm.sh/chart: {{ include "epi.chart" . }}
{{ include "epi.selectorLabels" . }}
{{- if .Chart.AppVersion }}
app.kubernetes.io/version: {{ .Chart.AppVersion | quote }}
{{- end }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
{{- end }}

{{/*
Selector labels
*/}}
{{- define "epi.selectorLabels" -}}
app.kubernetes.io/name: {{ include "epi.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
{{- end }}

{{/*
Create the name of the service account to use
*/}}
{{- define "epi.serviceAccountName" -}}
{{- if .Values.serviceAccount.create }}
{{- default (include "epi.fullname" .) .Values.serviceAccount.name }}
{{- else }}
{{- default "default" .Values.serviceAccount.name }}
{{- end }}
{{- end }}


{{/*
The Name of the ConfigMap for the Seeds Data
*/}}
{{- define "epi.configMapSeedsBackupName" -}}
{{- printf "%s-%s" (include "epi.fullname" .) "seedsbackup" }}
{{- end }}

{{/*
Lookup potentially existing seedsBackup data
*/}}
{{- define "epi.seedsBackupData" -}}
{{- $configMap := lookup "v1" "ConfigMap" .Release.Namespace (include "epi.configMapSeedsBackupName" .) -}}
{{- if $configMap -}}
{{/*
    Reusing existing data
*/}}
seedsBackup: {{ $configMap.data.seedsBackup | default "" | quote }}
{{- else -}}
{{/*
    Use new data
*/}}
seedsBackup: ""
{{- end -}}
{{- end -}}