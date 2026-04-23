#!/bin/bash

# Setup script for Exercise 4: Deployments and Updates

echo "==== Setting up Exercise 4: Deployments and Updates ===="

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

# Create deployment.yaml manifest
echo "Creating Deployment manifest file..."
cat > manifests/deployment.yaml << EOF
apiVersion: apps/v1
kind: Deployment
metadata:
  name: podinfo
  labels:
    app: podinfo
spec:
  replicas: 3
  selector:
    matchLabels:
      app: podinfo
  strategy:
    rollingUpdate:
      maxSurge: 1
      maxUnavailable: 1
    type: RollingUpdate
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

echo "✅ Created Deployment manifest: manifests/deployment.yaml"

# Check if podinfo deployment already exists and delete it if it does
if kubectl get deployment podinfo &> /dev/null; then
    echo "Found existing podinfo deployment. Deleting it..."
    kubectl delete deployment podinfo
    
    # Wait for deployment to be deleted
    while kubectl get deployment podinfo &> /dev/null; do
        echo "Waiting for deployment to be deleted..."
        sleep 2
    done
    echo "✅ Existing deployment deleted."
fi

# Check if podinfo service already exists and delete it if it does
if kubectl get service podinfo &> /dev/null; then
    echo "Found existing podinfo service. Deleting it..."
    kubectl delete service podinfo
    
    # Wait for service to be deleted
    while kubectl get service podinfo &> /dev/null; do
        echo "Waiting for service to be deleted..."
        sleep 2
    done
    echo "✅ Existing service deleted."
fi

echo ""
echo "==== Setup Complete! ===="
echo "You're now ready to start Exercise 4."
echo ""
echo "Next steps:"
echo "1. Review the Deployment manifest in manifests/deployment.yaml"
echo "2. Create the Deployment using: kubectl apply -f manifests/deployment.yaml"
echo "3. Follow the instructions in the README.md file"
echo ""
