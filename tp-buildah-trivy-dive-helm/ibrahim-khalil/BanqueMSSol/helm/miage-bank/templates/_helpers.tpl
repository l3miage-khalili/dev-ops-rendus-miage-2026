{{/*
Nom du chart
*/}}
{{- define "miage-bank.name" -}}
{{- .Chart.Name }}
{{- end }}

{{/*
Namespace cible
*/}}
{{- define "miage-bank.namespace" -}}
{{- .Values.global.namespace }}
{{- end }}

{{/*
Labels communs appliqués à toutes les ressources
*/}}
{{- define "miage-bank.labels" -}}
helm.sh/chart: {{ .Chart.Name }}-{{ .Chart.Version | replace "+" "_" }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
app.kubernetes.io/version: {{ .Chart.AppVersion | quote }}
app.kubernetes.io/part-of: miage-bank
{{- end }}

{{/*
Labels de sélection pour un service donné
Usage : include "miage-bank.selectorLabels" (dict "name" "banque-clientservice" "release" .Release.Name)
*/}}
{{- define "miage-bank.selectorLabels" -}}
app.kubernetes.io/name: {{ .name }}
app.kubernetes.io/instance: {{ .release }}
{{- end }}

{{/*
Référence complète de l'image OCI
Usage : include "miage-bank.image" (dict "registry" .Values.image.registry "image" $svc.image "tag" .Values.image.tag)
*/}}
{{- define "miage-bank.image" -}}
{{- if .registry -}}
{{ .registry }}/{{ .image }}:{{ .tag }}
{{- else -}}
{{ .image }}:{{ .tag }}
{{- end }}
{{- end }}
