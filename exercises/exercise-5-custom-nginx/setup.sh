#!/bin/bash

# Setup script for Exercise 5: Custom Nginx Deployment

echo "==== Setting up Exercise 5: Custom Nginx Deployment ===="

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

# Check if Docker is installed
if ! command -v docker &> /dev/null; then
    echo "❌ Docker not found! Please complete Exercise 1 first."
    exit 1
fi

echo "✅ Docker is installed."

# Create manifests directory if it doesn't exist
mkdir -p manifests

# Create deployment manifest
echo "Creating Deployment manifest file..."
cat > manifests/nginx-deployment.yaml << EOF
apiVersion: apps/v1
kind: Deployment
metadata:
  name: custom-nginx
  labels:
    app: custom-nginx
spec:
  replicas: 1
  selector:
    matchLabels:
      app: custom-nginx
  template:
    metadata:
      labels:
        app: custom-nginx
    spec:
      containers:
      - name: nginx
        image: custom-nginx:v1
        ports:
        - containerPort: 80
        resources:
          requests:
            memory: "64Mi"
            cpu: "100m"
          limits:
            memory: "128Mi"
            cpu: "200m"
EOF

echo "✅ Created Deployment manifest: manifests/nginx-deployment.yaml"

# Create service manifest
echo "Creating Service manifest file..."
cat > manifests/nginx-service.yaml << EOF
apiVersion: v1
kind: Service
metadata:
  name: custom-nginx
  labels:
    app: custom-nginx
spec:
  type: ClusterIP
  ports:
  - port: 80
    targetPort: 80
    protocol: TCP
    name: http
  selector:
    app: custom-nginx
EOF

echo "✅ Created Service manifest: manifests/nginx-service.yaml"

# Check and delete existing resources if they exist
if kubectl get deployment custom-nginx &> /dev/null; then
    echo "Found existing custom-nginx deployment. Deleting it..."
    kubectl delete deployment custom-nginx
    
    # Wait for deployment to be deleted
    while kubectl get deployment custom-nginx &> /dev/null; do
        echo "Waiting for deployment to be deleted..."
        sleep 2
    done
    echo "✅ Existing deployment deleted."
fi

if kubectl get service custom-nginx &> /dev/null; then
    echo "Found existing custom-nginx service. Deleting it..."
    kubectl delete service custom-nginx
    
    # Wait for service to be deleted
    while kubectl get service custom-nginx &> /dev/null; do
        echo "Waiting for service to be deleted..."
        sleep 2
    done
    echo "✅ Existing service deleted."
fi

echo ""
echo "==== Setup Complete! ===="
echo "You're now ready to start Exercise 5."
echo ""
echo "Next steps:"
echo "1. Review the files in this directory:"
echo "   - Dockerfile: Defines how to build your custom Nginx image"
echo "   - index.html: The custom webpage that will be served"
echo "   - manifests/nginx-deployment.yaml: Kubernetes Deployment definition"
echo "   - manifests/nginx-service.yaml: Kubernetes Service definition"
echo "2. Follow the instructions in the README.md file"
echo ""
