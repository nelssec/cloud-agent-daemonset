# Qualys Cloud Agent - Helm Chart Installation Guide

## Complete Helm Chart Deployment (No Scripts Required)

This guide shows how to deploy Qualys Cloud Agent using pure Helm commands. Everything is handled through `helm install` with parameters.

## Directory Structure

Create this structure for your Helm chart:

```
qualys-cloud-agent/
├── Chart.yaml
├── values.yaml
├── templates/
│   ├── _helpers.tpl
│   ├── namespace.yaml
│   ├── secret.yaml
│   ├── configmap.yaml
│   ├── serviceaccount.yaml
│   ├── rbac.yaml
│   ├── daemonset.yaml
│   └── NOTES.txt
└── docker/
    ├── Dockerfile
    └── packages/
        ├── qualys-cloud-agent-x64.rpm
        ├── qualys-cloud-agent-arm64.rpm
        ├── qualys-cloud-agent-x64.deb
        └── qualys-cloud-agent-arm64.deb
```

## Step 1: Build Container Image

```bash
# Add Qualys packages to docker/packages/
cd docker/
docker build -t your-registry.com/qualys-cloud-agent:1.0.0 .
docker push your-registry.com/qualys-cloud-agent:1.0.0
cd ..
```

## Step 2: Install with Single Command

### Option A: Direct Installation (Recommended)

```bash
helm install qualys-agent ./qualys-cloud-agent \
  --create-namespace \
  --namespace qualys-agent \
  --set qualys.activationId="YOUR_ACTIVATION_ID" \
  --set qualys.customerId="YOUR_CUSTOMER_ID" \
  --set qualys.serverUri="https://qagpublic.qg2.apps.qualys.com/CloudAgent/" \
  --set image.repository="your-registry.com/qualys-cloud-agent" \
  --set image.tag="1.0.0"
```

### Option B: Using Environment Variables

```bash
export ACTIVATION_ID="your-activation-id"
export CUSTOMER_ID="your-customer-id"
export SERVER_URI="https://qagpublic.qg2.apps.qualys.com/CloudAgent/"
export REGISTRY="your-registry.com"

helm install qualys-agent ./qualys-cloud-agent \
  --create-namespace \
  --namespace qualys-agent \
  --set qualys.activationId="${ACTIVATION_ID}" \
  --set qualys.customerId="${CUSTOMER_ID}" \
  --set qualys.serverUri="${SERVER_URI}" \
  --set image.repository="${REGISTRY}/qualys-cloud-agent"

# Clear sensitive variables
unset ACTIVATION_ID CUSTOMER_ID
```

### Option C: Using Override File

Create `production.yaml`:

```yaml
qualys:
  activationId: "YOUR_ACTIVATION_ID"
  customerId: "YOUR_CUSTOMER_ID"
  serverUri: "https://qagpublic.qg2.apps.qualys.com/CloudAgent/"

image:
  repository: "your-registry.com/qualys-cloud-agent"
  tag: "1.0.0"

resources:
  limits:
    cpu: 500m
    memory: 512Mi
  requests:
    cpu: 100m
    memory: 128Mi

nodeSelector:
  kubernetes.io/os: linux
  node-role.kubernetes.io/worker: ""
```

Install:

```bash
helm install qualys-agent ./qualys-cloud-agent \
  --create-namespace \
  --namespace qualys-agent \
  -f production.yaml
```

## Common Installation Scenarios

### 1. Basic Installation (All Defaults)

```bash
helm install qualys-agent ./qualys-cloud-agent \
  --set qualys.activationId="ABC123" \
  --set qualys.customerId="XYZ789" \
  --set qualys.serverUri="https://qualys.server.com/CloudAgent/" \
  --set image.repository="registry.company.com/qualys-agent"
```

### 2. Production with Resource Limits

```bash
helm install qualys-agent ./qualys-cloud-agent \
  --create-namespace \
  --namespace qualys-agent \
  --set qualys.activationId="ABC123" \
  --set qualys.customerId="XYZ789" \
  --set qualys.serverUri="https://qualys.server.com/CloudAgent/" \
  --set image.repository="registry.company.com/qualys-agent" \
  --set image.tag="1.0.0" \
  --set resources.limits.cpu="1000m" \
  --set resources.limits.memory="1Gi" \
  --set resources.requests.cpu="200m" \
  --set resources.requests.memory="256Mi"
```

### 3. Deploy Only on Specific Nodes

```bash
helm install qualys-agent ./qualys-cloud-agent \
  --set qualys.activationId="ABC123" \
  --set qualys.customerId="XYZ789" \
  --set qualys.serverUri="https://qualys.server.com/CloudAgent/" \
  --set image.repository="registry.company.com/qualys-agent" \
  --set nodeSelector."kubernetes\.io/os"="linux" \
  --set nodeSelector."node-role\.kubernetes\.io/worker"="" \
  --set nodeSelector."qualys-agent"="enabled"
```

### 4. With Private Registry

```bash
# Create pull secret
kubectl create secret docker-registry registry-secret \
  --namespace qualys-agent \
  --docker-server=private-registry.company.com \
  --docker-username=USERNAME \
  --docker-password=PASSWORD

# Install with pull secret
helm install qualys-agent ./qualys-cloud-agent \
  --namespace qualys-agent \
  --set qualys.activationId="ABC123" \
  --set qualys.customerId="XYZ789" \
  --set qualys.serverUri="https://qualys.server.com/CloudAgent/" \
  --set image.repository="private-registry.company.com/qualys-agent" \
  --set image.pullSecrets[0].name="registry-secret"
```

### 5. Using External Secret Manager

```bash
# Create secret manually (or via external secret manager)
kubectl create secret generic qualys-credentials \
  --namespace qualys-agent \
  --from-literal=activation-id="ABC123" \
  --from-literal=customer-id="XYZ789" \
  --from-literal=server-uri="https://qualys.server.com/CloudAgent/"

# Install referencing existing secret
helm install qualys-agent ./qualys-cloud-agent \
  --namespace qualys-agent \
  --set qualys.existingSecret.enabled=true \
  --set qualys.existingSecret.name="qualys-credentials" \
  --set image.repository="registry.company.com/qualys-agent"
```

## Verification Commands

```bash
# Check installation status
helm status qualys-agent -n qualys-agent

# List all resources
kubectl get all -n qualys-agent

# Check DaemonSet
kubectl get daemonset -n qualys-agent

# View pods on each node
kubectl get pods -n qualys-agent -o wide

# Check logs
kubectl logs -n qualys-agent -l app.kubernetes.io/name=qualys-cloud-agent

# Verify agent on host
POD=$(kubectl get pods -n qualys-agent -o jsonpath='{.items[0].metadata.name}')
kubectl exec -n qualys-agent $POD -- \
  nsenter --target 1 --mount --uts --ipc --net --pid \
  systemctl status qualys-cloud-agent

# Check secret (won't show values)
kubectl get secret -n qualys-agent

# Verify using secretKeyRef
kubectl get daemonset -n qualys-agent -o yaml | grep -A3 "ACTIVATION_ID"
```

## Upgrade

```bash
# Upgrade with new image version
helm upgrade qualys-agent ./qualys-cloud-agent \
  --namespace qualys-agent \
  --reuse-values \
  --set image.tag="1.0.1"

# Upgrade with changed configuration
helm upgrade qualys-agent ./qualys-cloud-agent \
  --namespace qualys-agent \
  --reuse-values \
  --set resources.limits.memory="1Gi"
```

## Rollback

```bash
# View history
helm history qualys-agent -n qualys-agent

# Rollback to previous version
helm rollback qualys-agent -n qualys-agent

# Rollback to specific revision
helm rollback qualys-agent 2 -n qualys-agent
```

## Uninstall

```bash
# Uninstall Helm release
helm uninstall qualys-agent -n qualys-agent

# Clean up namespace
kubectl delete namespace qualys-agent
```

## Advanced Helm Options

### Dry Run

```bash
helm install qualys-agent ./qualys-cloud-agent \
  --dry-run --debug \
  --set qualys.activationId="TEST" \
  --set qualys.customerId="TEST" \
  --set qualys.serverUri="https://test.com/CloudAgent/" \
  --set image.repository="test/qualys-agent"
```

### Generate Manifests Only

```bash
helm template qualys-agent ./qualys-cloud-agent \
  --namespace qualys-agent \
  --set qualys.activationId="ABC123" \
  --set qualys.customerId="XYZ789" \
  --set qualys.serverUri="https://qualys.server.com/CloudAgent/" \
  --set image.repository="registry.company.com/qualys-agent" \
  > qualys-manifests.yaml
```

### Wait for Deployment

```bash
helm install qualys-agent ./qualys-cloud-agent \
  --wait --timeout 5m \
  --set qualys.activationId="ABC123" \
  --set qualys.customerId="XYZ789" \
  --set qualys.serverUri="https://qualys.server.com/CloudAgent/" \
  --set image.repository="registry.company.com/qualys-agent"
```

## Helm Values Reference

### Minimal values.yaml

```yaml
# Only set defaults, pass credentials via --set
qualys:
  activationId: ""
  customerId: ""
  serverUri: "https://qagpublic.qg2.apps.qualys.com/CloudAgent/"
  logLevel: 3

image:
  repository: ""
  tag: "1.0.0"
  pullPolicy: IfNotPresent

namespace: qualys-agent
createNamespace: true
```

### Full values.yaml with all options

```yaml
qualys:
  activationId: ""  # Required via --set
  customerId: ""    # Required via --set
  serverUri: ""     # Required via --set
  logLevel: 3
  
  existingSecret:
    enabled: false
    name: ""
    keys:
      activationId: "activation-id"
      customerId: "customer-id"
      serverUri: "server-uri"

image:
  repository: ""  # Required via --set
  tag: "1.0.0"
  pullPolicy: IfNotPresent
  pullSecrets: []

daemonset:
  updateStrategy:
    type: RollingUpdate
    rollingUpdate:
      maxUnavailable: 1
  securityContext:
    privileged: true
    capabilities:
      add: [SYS_ADMIN, SYS_PTRACE, SYS_CHROOT]
    runAsUser: 0
    runAsNonRoot: false
  hostNetwork: true
  hostPID: true
  hostIPC: false
  dnsPolicy: ClusterFirstWithHostNet

resources:
  limits:
    cpu: 500m
    memory: 512Mi
  requests:
    cpu: 100m
    memory: 128Mi

nodeSelector: {}
tolerations:
  - operator: Exists
affinity: {}

serviceAccount:
  create: true
  annotations: {}
  name: ""

rbac:
  create: true

namespace: qualys-agent
createNamespace: true

healthChecks:
  liveness:
    enabled: true
    initialDelaySeconds: 120
    periodSeconds: 60
    timeoutSeconds: 10
    failureThreshold: 3
  readiness:
    enabled: true
    initialDelaySeconds: 30
    periodSeconds: 30
    timeoutSeconds: 10
    failureThreshold: 3

monitoring:
  enabled: true
  interval: 60
  timeout: 10

validation:
  required: true
  checkSecret: true

podAnnotations: {}
podLabels: {}
```

## Security Best Practices

1. **Never commit credentials to Git**
   - Use `--set` flags during installation
   - Use environment variables
   - Use external secret managers

2. **Use namespaces**
   - Always deploy to a dedicated namespace
   - Use `--create-namespace` flag

3. **Set resource limits**
   - Always configure CPU and memory limits
   - Prevent resource exhaustion

4. **Use RBAC**
   - Keep `rbac.create=true`
   - Review generated permissions

5. **Verify secret usage**
   - Check that credentials are in Secrets, not ConfigMaps
   - Verify `secretKeyRef` usage

## Troubleshooting

### Error: Missing Required Values

```bash
Error: qualys.activationId is required. Set with: --set qualys.activationId=YOUR_ID
```

Solution: Provide all required values:

```bash
helm install qualys-agent ./qualys-cloud-agent \
  --set qualys.activationId="ABC123" \
  --set qualys.customerId="XYZ789" \
  --set qualys.serverUri="https://server/CloudAgent/" \
  --set image.repository="registry/qualys-agent"
```

### Error: ImagePullBackOff

Check image repository and credentials:

```bash
kubectl describe pod -n qualys-agent <pod-name>
```

### Agent Not Starting

Check logs:

```bash
kubectl logs -n qualys-agent <pod-name>
```

## Summary

With this Helm chart approach:
- Single command installation
- All configuration via `helm install` flags
- Credentials stored securely in Kubernetes Secrets
- No external scripts required
- Standard Helm upgrade/rollback capabilities

Just run:

```bash
helm install qualys-agent ./qualys-cloud-agent \
  --set qualys.activationId="YOUR_ID" \
  --set qualys.customerId="YOUR_CUSTOMER" \
  --set qualys.serverUri="YOUR_URI" \
  --set image.repository="YOUR_REGISTRY/qualys-agent"
```

And your Qualys Cloud Agent is deployed securely across your cluster!
