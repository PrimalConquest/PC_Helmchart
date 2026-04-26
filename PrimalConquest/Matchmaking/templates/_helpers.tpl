{{- define "matchmaking.labels" -}}
app: {{ .Release.Name }}-{{ .Values.matchmaking.name }}
{{- end }}

{{- define "matchmaking.deployment.name" -}}
{{ .Release.Name }}-deployment-{{ .Values.matchmaking.name }}
{{- end }}

{{- define "matchmaking.service.name" -}}
{{ .Release.Name }}-service-{{ .Values.matchmaking.name }}
{{- end }}

{{- define "matchmaking.image" -}}
{{ .Values.global.registry }}/{{ .Values.matchmaking.image.repository }}:{{ .Values.matchmaking.image.tag }}
{{- end }}

{{- define "matchmaking.ingress.name" -}}
{{ .Release.Name }}-ingress-mm
{{- end }}

{{- define "matchmaking.middleware.strip" -}}
{{ .Release.Name }}-strip-mm
{{- end }}
