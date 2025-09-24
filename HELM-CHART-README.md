# Qualys Cloud Agent Helm Chart

Deploy Qualys Cloud Agent on Kubernetes with a single Helm command. All credentials are securely stored in Kubernetes Secrets.

## Prerequisites

- Kubernetes 1.19+
- Helm 3.8+
- Container image with Qualys packages (see Docker section)
- Qualys VMDR subscription with activation credentials

## Quick Install

```bash
helm install qualys-agent qualys-cloud-agent/ \
  --create-namespace \
  --namespace qualys-agent \
  --set qualys.activationId="YOUR_ACTIVATION_ID" \
  --set qualys.customerId="YOUR_CUSTOMER_ID" \
  --set qualys.serverUri="https://qagpublic.qg2.apps.qualys.com/CloudAgent/" \
  --set image.repository="your-registry.com/qualys-cloud-agent" \
  --set image.tag="1.0.0"
```

The chart will:
- Create the namespace
- Create a Kubernetes Secret with your credentials
- Deploy the DaemonSet on all nodes
- Start monitoring with the Qualys agent

## Installation Options

### Basic Installation

```bash
helm install qualys-agent . \
  --set qualys.activationId="$ACTIVATION_ID" \
  --set qualys.customerId="$CUSTOMER_ID" \
  --set qualys.serverUri="$SERVER_URI" \
  --set image.repository="$REGISTRY/qualys-cloud-agent"
```

### Production Installation

```bash
helm install qualys-agent . \
  --create-namespace \
  --namespace qualys-agent \
  --set qualys.activationId="$ACTIVATION_ID" \
  --set qualys.customerId="$CUSTOMER_ID" \
  --set qualys.serverUri="https://qagpublic.qg2.apps.qualys.com/CloudAgent/" \
  --set image.repository="your-registry.com/qualys-cloud-agent" \
  --set image.tag="1.0.0" \
  --set resources.limits.cpu="500m" \
  --set resources.limits.memory="512Mi" \
  --set resources.requests.cpu="100m" \
  --set resources.requests.memory="128Mi" \
  --set nodeSelector."kubernetes\.io/os"="linux" \
  --set rbac.create=true \
  --set serviceAccount.create=true
```

### Using External Secret

If you prefer to manage the secret separately:

```bash
# Create secret first
kubectl create namespace qualys-agent
kubectl create secret generic qualys-credentials \
  --namespace qualys-agent \
  --from-literal=activation-id="YOUR_ACTIVATION_ID" \
  --from-literal=customer-id="YOUR_CUSTOMER_ID" \
  --from-literal=server-uri="https://your-server/CloudAgent/"

# Install chart referencing the secret
helm install qualys-agent . \
  --namespace qualys-agent \
  --set qualys.existingSecret.enabled=true \
  --set qualys.existingSecret.name="qualys-credentials" \
  --set image.repository="your-registry.com/qualys-cloud-agent"
```

### Using Values File

Create `my-values.yaml`:

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

nodeSelector:
  kubernetes.io/os: linux
```

Install:

```bash
helm install qualys-agent . -f my-values.yaml
```

## Configuration Parameters

### Required Parameters

| Parameter | Description | Example |
|-----------|-------------|---------|
| `qualys.activationId` | Qualys activation ID | `--set qualys.activationId="12345678-1234..."` |
| `qualys.customerId` | Qualys customer ID | `--set qualys.customerId="abcdef12-3456..."` |
| `qualys.serverUri` | Qualys server endpoint | `--set qualys.serverUri="https://..."` |
| `image.repository` | Container registry path | `--set image.repository="registry/image"` |

### Optional Parameters

| Parameter | Description | Default |
|-----------|-------------|---------|
| `image.tag` | Image version | `1.0.0` |
| `namespace` | Target namespace | `qualys-agent` |
| `createNamespace` | Auto-create namespace | `true` |
| `resources.limits.cpu` | CPU limit | `500m` |
| `resources.limits.memory` | Memory limit | `512Mi` |
| `resources.requests.cpu` | CPU request | `100m` |
| `resources.requests.memory` | Memory request | `128Mi` |
| `nodeSelector` | Node selection | `{}` |
| `tolerations` | Pod tolerations | `[{operator: Exists}]` |
| `rbac.create` | Create RBAC resources | `true` |
| `serviceAccount.create` | Create service account | `true` |
| `qualys.logLevel` | Agent log level | `3` |

### Security Parameters

| Parameter | Description | Default |
|-----------|-------------|---------|
| `qualys.existingSecret.enabled` | Use existing secret | `false` |
| `qualys.existingSecret.name` | Existing secret name | `""` |
| `image.pullSecrets` | Registry pull secrets | `[]` |
| `daemonset.securityContext.privileged` | Privileged mode | `true` |

## Advanced Usage

### Deploy on Specific Nodes

```bash
helm install qualys-agent . \
  --set qualys.activationId="$ACTIVATION_ID" \
  --set qualys.customerId="$CUSTOMER_ID" \
  --set qualys.serverUri="$SERVER_URI" \
  --set image.repository="$REGISTRY/qualys-cloud-agent" \
  --set nodeSelector."qualys-agent"="enabled"
```

### Custom Tolerations

```bash
helm install qualys-agent . \
  --set qualys.activationId="$ACTIVATION_ID" \
  --set qualys.customerId="$CUSTOMER_ID" \
  --set qualys.serverUri="$SERVER_URI" \
  --set image.repository="$REGISTRY/qualys-cloud-agent" \
  --set tolerations[0].key="dedicated" \
  --set tolerations[0].operator="Equal" \
  --set tolerations[0].value="security" \
  --set tolerations[0].effect="NoSchedule"
```

### Private Registry

```bash
helm install qualys-agent . \
  --set qualys.activationId="$ACTIVATION_ID" \
  --set qualys.customerId="$CUSTOMER_ID" \
  --set qualys.serverUri="$SERVER_URI" \
  --set image.repository="private-registry.com/qualys-cloud-agent" \
  --set image.pullSecrets[0].name="registry-credentials"
```

## Upgrade

```bash
helm upgrade qualys-agent . \
  --reuse-values \
  --set image.tag="1.0.1"
```

## Uninstall

```bash
helm uninstall qualys-agent -n qualys-agent
kubectl delete namespace qualys-agent
```

## Verification

### Check Deployment

```bash
# Check DaemonSet
helm status qualys-agent -n qualys-agent

# View pods
kubectl get pods -n qualys-agent

# Check logs
kubectl logs -n qualys-agent -l app.kubernetes.io/name=qualys-cloud-agent

# Verify agent on host
POD=$(kubectl get pods -n qualys-agent -o jsonpath='{.items[0].metadata.name}')
kubectl exec -n qualys-agent $POD -- nsenter --target 1 --mount --uts --ipc --net --pid systemctl status qualys-cloud-agent
```

### Security Verification

```bash
# Verify credentials are in Secret (not ConfigMap)
kubectl get secret -n qualys-agent
kubectl get secret qualys-agent-secret -n qualys-agent -o yaml

# Confirm DaemonSet uses secretKeyRef
kubectl get daemonset -n qualys-agent -o yaml | grep secretKeyRef
```

## Docker Image Build

Before installing the Helm chart, build the container image:

```bash
cd docker/
# Add Qualys packages to packages/ directory
docker build -t your-registry.com/qualys-cloud-agent:1.0.0 .
docker push your-registry.com/qualys-cloud-agent:1.0.0
```

## Chart Structure

```
qualys-cloud-agent/
├── Chart.yaml                 # Chart metadata
├── values.yaml               # Default values
└── templates/
    ├── _helpers.tpl          # Template helpers
    ├── namespace.yaml        # Namespace creation
    ├── secret.yaml          # Credential storage
    ├── configmap.yaml       # Install script
    ├── serviceaccount.yaml  # Service account
    ├── rbac.yaml           # RBAC rules
    ├── daemonset.yaml      # Agent DaemonSet
    └── NOTES.txt           # Post-install notes
```

## Security Notes

- Credentials are stored in Kubernetes Secrets (base64 encoded, encrypted at rest)
- DaemonSet uses `secretKeyRef` to access credentials
- No credentials in ConfigMaps or container images
- Only `/tmp` is mounted from host for security

## Troubleshooting

### Missing Credentials Error

```bash
# Ensure all required values are set
helm install qualys-agent . \
  --set qualys.activationId="REQUIRED" \
  --set qualys.customerId="REQUIRED" \
  --set qualys.serverUri="REQUIRED" \
  --set image.repository="REQUIRED"
```

### Pull Image Error

```bash
# Add pull secret for private registry
kubectl create secret docker-registry registry-creds \
  --namespace qualys-agent \
  --docker-server=your-registry.com \
  --docker-username=YOUR_USERNAME \
  --docker-password=YOUR_PASSWORD

helm install qualys-agent . \
  --set image.pullSecrets[0].name="registry-creds" \
  ...
```

### Agent Not Starting

```bash
# Check pod logs
kubectl logs -n qualys-agent <pod-name>

# Check host agent logs
kubectl exec -n qualys-agent <pod-name> -- \
  nsenter --target 1 --mount --uts --ipc --net --pid \
  journalctl -u qualys-cloud-agent
```

## Support

- Helm Chart Issues: Check this README
- Qualys Agent Issues: Contact Qualys Support
- Security Questions: Review secret configuration

## License

Proprietary - Qualys Inc.
