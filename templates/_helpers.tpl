{{/*
Expand the name of the chart.
*/}}
{{- define "nectar-metrics.name" -}}
{{- default .Chart.Name .Values.nameOverride | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Create a default fully qualified app name, truncated at 63 chars.
*/}}
{{- define "nectar-metrics.fullname" -}}
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
{{- define "nectar-metrics.chart" -}}
{{- printf "%s-%s" .Chart.Name .Chart.Version | replace "+" "_" | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Common labels
*/}}
{{- define "nectar-metrics.labels" -}}
helm.sh/chart: {{ include "nectar-metrics.chart" . }}
{{ include "nectar-metrics.selectorLabels" . }}
{{- if .Chart.AppVersion }}
app.kubernetes.io/version: {{ .Chart.AppVersion | quote }}
{{- end }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
{{- end }}

{{/*
Selector labels
*/}}
{{- define "nectar-metrics.selectorLabels" -}}
app.kubernetes.io/name: {{ include "nectar-metrics.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
{{- end }}

{{/*
Service URL of a vmsingle instance (operator naming convention:
vmsingle-<cr name>).
*/}}
{{- define "nectar-metrics.vmsingleUrl" -}}
{{- printf "http://vmsingle-%s-%s.%s.svc:8428" (include "nectar-metrics.fullname" .ctx) .suffix .ctx.Release.Namespace }}
{{- end }}

{{/*
Write endpoint (vmagent) and read endpoint (vmauth) service URLs.
*/}}
{{- define "nectar-metrics.writeUrl" -}}
{{- printf "http://vmagent-%s.%s.svc:8429" (include "nectar-metrics.fullname" .) .Release.Namespace }}
{{- end }}

{{- define "nectar-metrics.readUrl" -}}
{{- printf "http://vmauth-%s.%s.svc:8427" (include "nectar-metrics.fullname" .) .Release.Namespace }}
{{- end }}
