{{- define "auth-service.fullName" }}
{{- printf "%s-%s" .Release.Name .Chart.Name }}
{{- end}}

{{- define "auth-service.labels" -}}
app: {{ .Chart.Name }}
release: {{ .Release.Name }}
{{- end}}

{{- define "auth-service.selectorLabels" -}}
app: {{ .Chart.Name }}
release: {{ .Release.Name }}
{{- end}}
