#!/bin/bash

# Check script for Exercise 5: Custom Nginx Deployment

echo "==== Checking Exercise 5: Custom Nginx Deployment ===="

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

# Check if custom-nginx deployment exists
if ! kubectl get deployment custom-nginx &> /dev/null; then
    echo "❌ custom-nginx deployment not found! Please create the deployment first."
    echo "   Run: kubectl apply -f manifests/nginx-deployment.yaml"
    exit 1
fi

echo "✅ custom-nginx deployment found."

# Check deployment status
AVAILABLE_REPLICAS=$(kubectl get deployment custom-nginx -o jsonpath='{.status.availableReplicas}')
if [ -z "$AVAILABLE_REPLICAS" ] || [ "$AVAILABLE_REPLICAS" -lt 1 ]; then
    echo "❌ custom-nginx deployment has no available replicas! Current status:"
    kubectl get deployment custom-nginx
    echo "   Check the deployment status with: kubectl describe deployment custom-nginx"
    exit 1
fi

echo "✅ custom-nginx deployment has $AVAILABLE_REPLICAS available replicas."

# Check if pods are running
POD_STATUS=$(kubectl get pods -l app=custom-nginx -o jsonpath='{.items[0].status.phase}')
if [ "$POD_STATUS" != "Running" ]; then
    echo "❌ custom-nginx pod is not running! Current status: $POD_STATUS"
    echo "   Check the pod status with: kubectl describe pod -l app=custom-nginx"
    exit 1
fi

echo "✅ custom-nginx pod is running."

# Check if container is ready
CONTAINER_READY=$(kubectl get pods -l app=custom-nginx -o jsonpath='{.items[0].status.containerStatuses[0].ready}')
if [ "$CONTAINER_READY" != "true" ]; then
    echo "❌ Nginx container is not ready!"
    echo "   Check the pod status with: kubectl describe pod -l app=custom-nginx"
    exit 1
fi

echo "✅ Nginx container is ready."

# Check if service exists
if ! kubectl get service custom-nginx &> /dev/null; then
    echo "❌ custom-nginx service not found! Please create the service first."
    echo "   Run: kubectl apply -f manifests/nginx-service.yaml"
    exit 1
fi

echo "✅ custom-nginx service found."

# Check if service targets the correct port
SERVICE_PORT=$(kubectl get service custom-nginx -o jsonpath='{.spec.ports[0].port}')
if [ "$SERVICE_PORT" != "80" ]; then
    echo "❌ custom-nginx service is not targeting the correct port! Current port: $SERVICE_PORT"
    echo "   Expected port: 80"
    exit 1
fi

echo "✅ custom-nginx service is targeting the correct port: $SERVICE_PORT."

# Check if service targets the correct pods
SERVICE_SELECTOR_APP=$(kubectl get service custom-nginx -o jsonpath='{.spec.selector.app}')
if [ "$SERVICE_SELECTOR_APP" != "custom-nginx" ]; then
    echo "❌ custom-nginx service is not selecting the correct pods! Current selector: $SERVICE_SELECTOR_APP"
    echo "   Expected selector: custom-nginx"
    exit 1
fi

echo "✅ custom-nginx service is selecting the correct pods."

# Attempt to access the service via port-forward
echo "Testing service accessibility via port-forward..."
PORT_FORWARD_PID=""

# Start port-forward in the background
kubectl port-forward svc/custom-nginx 8080:80 &> /dev/null & 
PORT_FORWARD_PID=$!

# Wait for port-forward to start
sleep 5

# Check if port-forward is working
if ! curl -s http://localhost:8080 | grep -q "Custom Nginx Container"; then
    echo "❌ custom-nginx service is not accessible via port-forward or custom content not found!"
    if [ ! -z "$PORT_FORWARD_PID" ]; then
        kill $PORT_FORWARD_PID &> /dev/null
    fi
    exit 1
fi

# Clean up port-forward
if [ ! -z "$PORT_FORWARD_PID" ]; then
    kill $PORT_FORWARD_PID &> /dev/null
fi

echo "✅ custom-nginx service is accessible via port-forward and custom content verified."

# Check if image is custom (just a basic check)
POD_IMAGE=$(kubectl get pods -l app=custom-nginx -o jsonpath='{.items[0].spec.containers[0].image}')
if [[ "$POD_IMAGE" != *"custom-nginx"* ]]; then
    echo "❌ Pod is not using the custom image! Current image: $POD_IMAGE"
    echo "   Did you build and load the custom image into KIND?"
    exit 1
fi

echo "✅ Pod is using the custom image: $POD_IMAGE."

echo "✅ All checks passed!"
echo "You've successfully completed Exercise 5."
echo "Next steps:"
echo "1. Try the challenges mentioned in the README.md"
echo "2. Experiment with different Service types and configurations"
echo "3. When ready, proceed to the next part of your Kubernetes journey!"
