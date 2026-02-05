{{- define "api-gateway.fullName" }}
{{- printf "%s-%s" .Release.Name .Chart.Name }}
{{- end}}

{{- define "api-gateway.labels" -}}
app: {{ .Chart.Name }}
release: {{ .Release.Name }}
{{- end}}

{{- define "api-gateway.selectorLabels" -}}
app: {{ .Chart.Name }}
release: {{ .Release.Name }}
{{- end}}
