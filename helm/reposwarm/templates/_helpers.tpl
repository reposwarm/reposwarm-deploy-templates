{{/*
Common labels
*/}}
{{- define "reposwarm.labels" -}}
app.kubernetes.io/managed-by: {{ .Release.Service }}
app.kubernetes.io/instance: {{ .Release.Name }}
app.kubernetes.io/version: {{ .Chart.AppVersion | quote }}
helm.sh/chart: {{ .Chart.Name }}-{{ .Chart.Version }}
{{- end }}

{{/*
Selector labels for a component
*/}}
{{- define "reposwarm.selectorLabels" -}}
app.kubernetes.io/name: {{ .name }}
app.kubernetes.io/instance: {{ .release }}
{{- end }}

{{/*
Temporal host — use in-cluster postgres or external RDS
*/}}
{{- define "reposwarm.temporalPostgresHost" -}}
{{- if and .Values.temporal.postgres.host (ne .Values.temporal.postgres.host "") -}}
{{ .Values.temporal.postgres.host }}
{{- else -}}
{{ .Release.Name }}-postgres
{{- end -}}
{{- end }}

{{/*
Full name helper
*/}}
{{- define "reposwarm.fullname" -}}
{{ .Release.Name }}
{{- end }}
