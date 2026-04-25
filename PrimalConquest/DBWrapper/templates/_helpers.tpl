

{{- define "database.postgres.labels" -}}
app: {{.Release.Name}}-{{ .values.postgres.name }}
{{- end }}

{{- define "database.postgres.pvc.name" -}}
{{ .Release.Name }}-pvc-{{ .values.postgres.name }}
{{- end }}

{{- define "database.postgres.deployment.name" -}}
{{ .Release.Name }}-deployment-{{ .values.postgres.name }}
{{- end }}

{{- define "database.postgres.service.name" -}}
{{ .Release.Name }}-service-{{ .values.postgres.name }}
{{- end }}




{{- define "database.wrapper.image" -}}
{{.values.global.registry}}/{{.values.dbWrapper.image.repository}}:{{.values.dbWrapper.image.tag}}
{{- end }}

{{- define "database.wrapper.labels" -}}
app: {{.Release.Name}}-{{ .values.dbWrapper.name }}
{{- end }}

{{- define "database.wrapper.deployment.name" -}}
{{ .Release.Name }}-deployment-{{ .values.dbWrapper.name }}
{{- end }}

{{- define "database.wrapper.service.name" -}}
{{ .Release.Name }}-service-{{ .values.dbWrapper.name }}
{{- end }}