{{- define "payflow.fullname" -}}
{{- if contains .Chart.Name .Release.Name -}}
{{- .Release.Name | trunc 63 | trimSuffix "-" -}}
{{- else -}}
{{- printf "%s-%s" .Release.Name .Chart.Name | trunc 63 | trimSuffix "-" -}}
{{- end -}}
{{- end -}}

{{- define "payflow.labels" -}}
helm.sh/chart: {{ printf "%s-%s" .Chart.Name .Chart.Version }}
app.kubernetes.io/name: {{ .Chart.Name }}
app.kubernetes.io/instance: {{ .Release.Name }}
app.kubernetes.io/version: {{ .Values.image.tag | default .Chart.AppVersion | quote }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
app.kubernetes.io/part-of: payflow
{{- end -}}

{{- define "payflow.selectorLabels" -}}
app.kubernetes.io/name: {{ .root.Chart.Name }}
app.kubernetes.io/instance: {{ .root.Release.Name }}
app.kubernetes.io/component: {{ .component }}
{{- end -}}

{{- define "payflow.image" -}}
{{ .Values.image.repository }}:{{ .Values.image.tag | default .Chart.AppVersion }}
{{- end -}}

{{/* Environment shared by web, worker, migration and cron pods. */}}
{{- define "payflow.envFrom" -}}
- configMapRef:
    name: {{ include "payflow.fullname" . }}
- secretRef:
    name: {{ .Values.existingSecret }}
{{- end -}}

{{/* /tmp is the only writable path; the root filesystem is read-only. */}}
{{- define "payflow.tmpVolume" -}}
- name: tmp
  emptyDir: {}
{{- end -}}

{{- define "payflow.tmpMount" -}}
- name: tmp
  mountPath: /tmp
{{- end -}}
