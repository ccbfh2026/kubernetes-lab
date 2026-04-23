#!/bin/bash

# Check script for Exercise 6: Kubernetes Services

echo "==== Checking Exercise 6: Kubernetes Services ===="

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

# Check if hello-deployment exists
if ! kubectl get deployment hello-deployment &> /dev/null; then
    echo "❌ hello-deployment not found! Please create the deployment first."
    echo "   Run: kubectl apply -f manifests/hello-deployment.yaml"
    exit 1
fi

echo "✅ hello-deployment found."

# Check deployment status
DESIRED_REPLICAS=$(kubectl get deployment hello-deployment -o jsonpath='{.spec.replicas}')
AVAILABLE_REPLICAS=$(kubectl get deployment hello-deployment -o jsonpath='{.status.availableReplicas}')

if [[ -z "$AVAILABLE_REPLICAS" || "$AVAILABLE_REPLICAS" -lt "$DESIRED_REPLICAS" ]]; then
    echo "❌ Not all desired pods are available! Desired: $DESIRED_REPLICAS, Available: $AVAILABLE_REPLICAS"
    echo "   Check the deployment status with: kubectl describe deployment hello-deployment"
    exit 1
fi

echo "✅ Deployment has $AVAILABLE_REPLICAS/$DESIRED_REPLICAS pods available."

# Check if ClusterIP service exists
if ! kubectl get service hello-service &> /dev/null; then
    echo "❌ hello-service (ClusterIP) not found! Please create the service."
    echo "   Run: kubectl apply -f manifests/clusterip-service.yaml"
    exit 1
fi

echo "✅ ClusterIP service found."

# Check if service has endpoints
ENDPOINTS=$(kubectl get endpoints hello-service -o jsonpath='{.subsets[0].addresses}')
if [[ -z "$ENDPOINTS" ]]; then
    echo "❌ ClusterIP service has no endpoints! Check that the service selector matches pod labels."
    echo "   Run: kubectl describe service hello-service"
    echo "   And: kubectl get pods --selector=app=hello"
    exit 1
fi

echo "✅ ClusterIP service has endpoints."

# Check if NodePort service exists
if ! kubectl get service hello-nodeport &> /dev/null; then
    echo "❌ hello-nodeport service not found! Please create the NodePort service."
    echo "   Run: kubectl apply -f manifests/nodeport-service.yaml"
    exit 1
fi

echo "✅ NodePort service found."

# Check if NodePort service has the correct type
SERVICE_TYPE=$(kubectl get service hello-nodeport -o jsonpath='{.spec.type}')
if [[ "$SERVICE_TYPE" != "NodePort" ]]; then
    echo "❌ hello-nodeport is not of type NodePort! Current type: $SERVICE_TYPE"
    exit 1
fi

echo "✅ NodePort service has correct type."

# Check if NodePort service has assigned port
NODE_PORT=$(kubectl get service hello-nodeport -o jsonpath='{.spec.ports[0].nodePort}')
if [[ -z "$NODE_PORT" ]]; then
    echo "❌ NodePort service doesn't have a nodePort assigned!"
    exit 1
fi

echo "✅ NodePort service has nodePort: $NODE_PORT"

# Check if service is accessible (only for KIND or similar setups)
if [[ "$KUBECONFIG" == *"kind"* || "$KUBECONFIG" == *"minikube"* || -n "${KIND_CLUSTER_NAME}" ]]; then
    # Try to access the service a few times
    for i in {1..3}; do
        if ! curl -s localhost:$NODE_PORT > /dev/null; then
            echo "⚠️ Could not access NodePort service at localhost:$NODE_PORT"
            echo "   This could be due to the KIND/Minikube setup or network policies."
            break
        fi
        
        # If we reach here on the last attempt, it worked
        if [[ $i -eq 3 ]]; then
            echo "✅ Successfully accessed NodePort service at localhost:$NODE_PORT"
        fi
    done
else
    echo "ℹ️ Not running on KIND or Minikube. Please manually verify access to the NodePort service."
    echo "   You can try: curl <node-ip>:$NODE_PORT"
fi

echo ""
echo "==== Exercise 6 Check Complete ===="
echo "You have successfully:"
echo "✅ Created a Deployment with multiple replicas"
echo "✅ Created a ClusterIP Service for internal communication"
echo "✅ Created a NodePort Service for external access"
echo ""
echo "Next steps:"
echo "- Try the service discovery with DNS (see README)"
echo "- Scale the deployment and observe endpoints change"
echo "- Try the challenge exercises"
echo ""
