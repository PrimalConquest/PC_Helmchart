

{{- define "database.postgres.labels" -}}
app: {{.Release.Name}}-{{ .Values.postgres.name }}
{{- end }}

{{- define "database.postgres.pvc.name" -}}
{{ .Release.Name }}-pvc-{{ .Values.postgres.name }}
{{- end }}

{{- define "database.postgres.deployment.name" -}}
{{ .Release.Name }}-deployment-{{ .Values.postgres.name }}
{{- end }}

{{- define "database.postgres.service.name" -}}
{{ .Release.Name }}-service-{{ .Values.postgres.name }}
{{- end }}




{{- define "database.wrapper.image" -}}
{{.Values.global.registry}}/{{.Values.dbWrapper.image.repository}}:{{.Values.dbWrapper.image.tag}}
{{- end }}

{{- define "database.wrapper.labels" -}}
app: {{.Release.Name}}-{{ .Values.dbWrapper.name }}
{{- end }}

{{- define "database.wrapper.deployment.name" -}}
{{ .Release.Name }}-deployment-{{ .Values.dbWrapper.name }}
{{- end }}

{{- define "database.wrapper.service.name" -}}
{{ .Release.Name }}-service-{{ .Values.dbWrapper.name }}
{{- end }}




{{- define "database.ingress.name" -}}
{{ .Release.Name }}-ingress-db
{{- end }}

{{- define "database.middleware.strip" -}}
{{ .Release.Name }}-strip-db
{{- end }}