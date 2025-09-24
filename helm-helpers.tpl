{{/*
Expand the name of the chart.
*/}}
{{- define "qualys-cloud-agent.name" -}}
{{- default .Chart.Name .Values.nameOverride | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Create a default fully qualified app name.
*/}}
{{- define "qualys-cloud-agent.fullname" -}}
{{- if .Values.fullnameOverride }}
{{- .Values.fullnameOverride | trunc 63 | trimSuffix "-" }}
{{- else }}
{{- $name := default .Chart.Name .Values.nameOverride }}
{{- if contains $name .Release.Name }}
{{- .Release.Name | trunc 63 | trimSuffix "-" }}
{{- else }}
{{- printf "%s-%s" .Release.Name $name | trunc 63 | trimSuffix "-" }}
{{- end }}
{{- end }}
{{- end }}

{{/*
Create chart name and version as used by the chart label.
*/}}
{{- define "qualys-cloud-agent.chart" -}}
{{- printf "%s-%s" .Chart.Name .Chart.Version | replace "+" "_" | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Common labels
*/}}
{{- define "qualys-cloud-agent.labels" -}}
helm.sh/chart: {{ include "qualys-cloud-agent.chart" . }}
{{ include "qualys-cloud-agent.selectorLabels" . }}
{{- if .Chart.AppVersion }}
app.kubernetes.io/version: {{ .Chart.AppVersion | quote }}
{{- end }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
app.kubernetes.io/component: security-agent
{{- end }}

{{/*
Selector labels
*/}}
{{- define "qualys-cloud-agent.selectorLabels" -}}
app.kubernetes.io/name: {{ include "qualys-cloud-agent.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
{{- end }}

{{/*
Create the name of the service account to use
*/}}
{{- define "qualys-cloud-agent.serviceAccountName" -}}
{{- if .Values.serviceAccount.create }}
{{- default (include "qualys-cloud-agent.fullname" .) .Values.serviceAccount.name }}
{{- else }}
{{- default "default" .Values.serviceAccount.name }}
{{- end }}
{{- end }}

{{/*
Validate required configuration
*/}}
{{- define "qualys-cloud-agent.validateConfig" -}}
{{- if .Values.validation.required }}
  {{- if not .Values.qualys.existingSecret.enabled }}
    {{- if not .Values.qualys.activationId }}
      {{- fail "ERROR: qualys.activationId is required. Set with: --set qualys.activationId=YOUR_ID" }}
    {{- end }}
    {{- if not .Values.qualys.customerId }}
      {{- fail "ERROR: qualys.customerId is required. Set with: --set qualys.customerId=YOUR_CUSTOMER" }}
    {{- end }}
    {{- if not .Values.qualys.serverUri }}
      {{- fail "ERROR: qualys.serverUri is required. Set with: --set qualys.serverUri=YOUR_URI" }}
    {{- end }}
  {{- else }}
    {{- if not .Values.qualys.existingSecret.name }}
      {{- fail "ERROR: qualys.existingSecret.name is required when existingSecret.enabled=true" }}
    {{- end }}
  {{- end }}
  {{- if not .Values.image.repository }}
    {{- fail "ERROR: image.repository is required. Set with: --set image.repository=your-registry.com/qualys-cloud-agent" }}
  {{- end }}
{{- end }}
{{- end }}

{{/*
Get the namespace
*/}}
{{- define "qualys-cloud-agent.namespace" -}}
{{- if .Values.namespace }}
{{- .Values.namespace }}
{{- else }}
{{- .Release.Namespace }}
{{- end }}
{{- end }}

{{/*
Generate environment variables for the agent
*/}}
{{- define "qualys-cloud-agent.env" -}}
{{- if .Values.qualys.existingSecret.enabled }}
# Using existing secret
- name: ACTIVATION_ID
  valueFrom:
    secretKeyRef:
      name: {{ .Values.qualys.existingSecret.name }}
      key: {{ .Values.qualys.existingSecret.keys.activationId }}
- name: CUSTOMER_ID
  valueFrom:
    secretKeyRef:
      name: {{ .Values.qualys.existingSecret.name }}
      key: {{ .Values.qualys.existingSecret.keys.customerId }}
- name: SERVER_URI
  valueFrom:
    secretKeyRef:
      name: {{ .Values.qualys.existingSecret.name }}
      key: {{ .Values.qualys.existingSecret.keys.serverUri }}
{{- else }}
# Using Helm-managed secret
- name: ACTIVATION_ID
  valueFrom:
    secretKeyRef:
      name: {{ include "qualys-cloud-agent.fullname" . }}-secret
      key: activation-id
- name: CUSTOMER_ID
  valueFrom:
    secretKeyRef:
      name: {{ include "qualys-cloud-agent.fullname" . }}-secret
      key: customer-id
- name: SERVER_URI
  valueFrom:
    secretKeyRef:
      name: {{ include "qualys-cloud-agent.fullname" . }}-secret
      key: server-uri
{{- end }}
- name: LOG_LEVEL
  value: {{ .Values.qualys.logLevel | quote }}
{{- end }}
