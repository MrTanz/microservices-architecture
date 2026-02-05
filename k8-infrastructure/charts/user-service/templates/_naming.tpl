{{- define "user-service.fullName" }}
{{- printf "%s-%s" .Release.Name .Chart.Name }}
{{- end}}

{{- define "user-service.labels" -}}
app: {{ .Chart.Name }}
release: {{ .Release.Name }}
{{- end}}

{{- define "user-service.selectorLabels" -}}
app: {{ .Chart.Name }}
release: {{ .Release.Name }}
{{- end}}
