
{{- define "common.fullname" -}}
{{- $defaultName := print "%s-%s" .Release.Name .Chart.Name }}
{{- .fullnameOverride | default $defaultName | trunc 63 | trimSuffix "-"  }}
{{- end }}

{{- define "common.labels" -}}
app: {{ .Chart.Name }}
release: {{ .Release.Name }}
{{- end }}