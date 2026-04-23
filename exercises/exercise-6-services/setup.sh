#!/bin/bash

# Setup script for Exercise 6: Kubernetes Services

echo "==== Setting up Exercise 6: Kubernetes Services ===="

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

# Create hello-deployment.yaml manifest
echo "Creating Deployment manifest file..."
cat > manifests/hello-deployment.yaml << EOF
apiVersion: apps/v1
kind: Deployment
metadata:
  name: hello-deployment
  labels:
    app: hello
spec:
  replicas: 3
  selector:
    matchLabels:
      app: hello
  template:
    metadata:
      labels:
        app: hello
    spec:
      containers:
      - name: hello-container
        image: stefanprodan/podinfo:6.3.5
        ports:
        - containerPort: 9898
        resources:
          requests:
            memory: "32Mi"
            cpu: "100m"
          limits:
            memory: "128Mi"
            cpu: "500m"
EOF

# Create clusterip-service.yaml manifest
echo "Creating ClusterIP Service manifest file..."
cat > manifests/clusterip-service.yaml << EOF
apiVersion: v1
kind: Service
metadata:
  name: hello-service
spec:
  selector:
    app: hello
  ports:
  - port: 8080
    targetPort: 9898
  type: ClusterIP
EOF

# Create nodeport-service.yaml manifest
echo "Creating NodePort Service manifest file..."
cat > manifests/nodeport-service.yaml << EOF
apiVersion: v1
kind: Service
metadata:
  name: hello-nodeport
spec:
  selector:
    app: hello
  ports:
  - port: 8080
    targetPort: 9898
    nodePort: 30000
  type: NodePort
EOF

# Check if resources already exist and delete them if they do
if kubectl get deployment hello-deployment &> /dev/null; then
    echo "Found existing hello-deployment. Deleting it..."
    kubectl delete deployment hello-deployment
    
    # Wait for deployment to be deleted
    while kubectl get deployment hello-deployment &> /dev/null; do
        echo "Waiting for deployment to be deleted..."
        sleep 2
    done
    echo "✅ Existing deployment deleted."
fi

if kubectl get service hello-service &> /dev/null; then
    echo "Found existing hello-service. Deleting it..."
    kubectl delete service hello-service
    
    # Wait for service to be deleted
    while kubectl get service hello-service &> /dev/null; do
        echo "Waiting for service to be deleted..."
        sleep 2
    done
    echo "✅ Existing ClusterIP service deleted."
fi

if kubectl get service hello-nodeport &> /dev/null; then
    echo "Found existing hello-nodeport service. Deleting it..."
    kubectl delete service hello-nodeport
    
    # Wait for service to be deleted
    while kubectl get service hello-nodeport &> /dev/null; do
        echo "Waiting for service to be deleted..."
        sleep 2
    done
    echo "✅ Existing NodePort service deleted."
fi

echo ""
echo "==== Setup Complete! ===="
echo "You're now ready to start Exercise 6."
echo ""
echo "Next steps:"
echo "1. Review the deployment and service manifests in the manifests directory"
echo "2. Create the deployment using: kubectl apply -f manifests/hello-deployment.yaml"
echo "3. Follow the instructions in the README.md file"
echo ""

# Check if we're using KIND
if kubectl cluster-info | grep -q "kind"; then
    echo "KIND cluster detected!"
    echo ""
    
    # Check if this is a multi-node setup
    NODE_COUNT=$(kubectl get nodes | grep -v NAME | wc -l)
    if [ "$NODE_COUNT" -gt "1" ]; then
        echo "Multi-node KIND cluster detected ($NODE_COUNT nodes)."
        
        # Check if port mapping exists in the KIND config
        if [ -f "../exercise-1-setup/kind-config.yaml" ]; then
            if grep -q "30080" "../exercise-1-setup/kind-config.yaml"; then
                echo "✅ Port 30080 appears to be mapped in your KIND configuration."
                echo "   You should be able to access the NodePort service at: localhost:30080"
            else
                echo "⚠️ Port 30080 does not appear to be mapped in your KIND configuration."
                echo "   The recommended way to access the service is using port-forward:"
                echo "   kubectl port-forward service/hello-nodeport 8080:8080"
                echo "   Then access it at: http://localhost:8080"
            fi
        else
            echo "⚠️ Could not find KIND configuration to check port mappings."
            echo "   The recommended way to access the service is using port-forward:"
            echo "   kubectl port-forward service/hello-nodeport 8080:8080"
            echo "   Then access it at: http://localhost:8080"
        fi
    else
        echo "Single-node KIND cluster detected."
        echo "⚠️ To access NodePort services in KIND, you can use port-forward:"
        echo "   kubectl port-forward service/hello-nodeport 8080:8080"
        echo "   Then access it at: http://localhost:8080"
    fi
    echo ""
fi
