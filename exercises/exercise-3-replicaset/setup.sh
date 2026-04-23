#!/bin/bash

# Setup script for Exercise 3: Working with ReplicaSets

echo "==== Setting up Exercise 3: Working with ReplicaSets ===="

# Ensure kubectl is installed and connected to a cluster
if ! command -v kubectl &> /dev/null; then
    echo "❌ kubectl not found! Please complete Exercise 1 first."
    exit 1
fi

# Check if cluster is accessible
if ! kubectl cluster-info &> /dev/null; then
    echo "❌ Cannot connect to Kubernetes cluster. Please make sure your cluster is running."
    exit 1
fi

echo "✅ Kubernetes cluster is accessible."

# Create manifests directory if it doesn't exist
mkdir -p manifests

# Create replicaset.yaml manifest
echo "Creating ReplicaSet manifest file..."
cat > manifests/replicaset.yaml << EOF
apiVersion: apps/v1
kind: ReplicaSet
metadata:
  name: podinfo-rs
  labels:
    app: podinfo
spec:
  replicas: 3
  selector:
    matchLabels:
      app: podinfo
  template:
    metadata:
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

echo "✅ Created ReplicaSet manifest: manifests/replicaset.yaml"

# Check if podinfo-rs replicaset already exists and delete it if it does
if kubectl get replicaset podinfo-rs &> /dev/null; then
    echo "Found existing podinfo-rs replicaset. Deleting it..."
    kubectl delete replicaset podinfo-rs
    
    # Wait for replicaset and its pods to be deleted
    while kubectl get replicaset podinfo-rs &> /dev/null; do
        echo "Waiting for replicaset to be deleted..."
        sleep 2
    done
    echo "✅ Existing replicaset deleted."
fi

echo ""
echo "==== Setup Complete! ===="
echo "You're now ready to start Exercise 3."
echo ""
echo "Next steps:"
echo "1. Review the ReplicaSet manifest in manifests/replicaset.yaml"
echo "2. Create the ReplicaSet using: kubectl apply -f manifests/replicaset.yaml"
echo "3. Follow the instructions in the README.md file"
echo ""
