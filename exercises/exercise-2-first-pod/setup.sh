#!/bin/bash

# Setup script for Exercise 2: Your First Pod

echo "==== Setting up Exercise 2: Your First Pod ===="

# Ensure kubectl is installed and connected to a cluster
if ! command -v kubectl &> /dev/null; then
    echo "❌ kubectl not found! Please complete Exercise 1 first."
    exit 1
fi

# Check if cluster is accessible
if ! kubectl cluster-info &> /dev/null; then
    echo "❌ Cannot connect to Kubernetes cluster. Please make sure your cluster is running."
    echo "   Run 'kind create cluster --name k8s-intro' if you haven't created a cluster yet."
    exit 1
fi

echo "✅ Kubernetes cluster is accessible."

# Create manifests directory if it doesn't exist
mkdir -p manifests

# Create pod.yaml manifest
echo "Creating Pod manifest file..."
cat > manifests/pod.yaml << EOF
apiVersion: v1
kind: Pod
metadata:
  name: podinfo
  labels:
    app: podinfo
spec:
  containers:
  - name: podinfo
    image: stefanprodan/podinfo:6.7.1
    ports:
    - containerPort: 9898
      name: http
    resources:
      requests:
        memory: "32Mi"
        cpu: "100m"
      limits:
        memory: "128Mi"
        cpu: "500m"
    env:
    - name: KUBERNETES_NAMESPACE
      valueFrom:
        fieldRef:
          fieldPath: metadata.namespace
    - name: KUBERNETES_POD_NAME
      valueFrom:
        fieldRef:
          fieldPath: metadata.name
    livenessProbe:
      httpGet:
        path: /healthz
        port: 9898
    readinessProbe:
      httpGet:
        path: /readyz
        port: 9898
EOF

echo "✅ Created Pod manifest: manifests/pod.yaml"

# Check if podinfo pod already exists and delete it if it does
if kubectl get pod podinfo &> /dev/null; then
    echo "Found existing podinfo pod. Deleting it..."
    kubectl delete pod podinfo
    
    # Wait for pod to be deleted
    while kubectl get pod podinfo &> /dev/null; do
        echo "Waiting for pod to be deleted..."
        sleep 2
    done
    echo "✅ Existing pod deleted."
fi

echo ""
echo "==== Setup Complete! ===="
echo "You're now ready to start Exercise 2."
echo ""
echo "Next steps:"
echo "1. Review the Pod manifest in manifests/pod.yaml"
echo "2. Create the Pod using: kubectl apply -f manifests/pod.yaml"
echo "3. Follow the instructions in the README.md file"
echo ""
