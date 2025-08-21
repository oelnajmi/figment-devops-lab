{{- define "myapp.name" -}}
{{ .Chart.Name }}
{{- end }}

{{- define "myapp.fullname" -}}
{{ include "myapp.name" . }}
{{- end }}

{{- define "myapp.labels" -}}
app.kubernetes.io/name: {{ include "myapp.name" . }}
app.kubernetes.io/instance: {{ include "myapp.fullname" . }}
{{- end }}

{{- define "myapp.selectorLabels" -}}
app.kubernetes.io/name: {{ include "myapp.name" . }}
{{- end }}
