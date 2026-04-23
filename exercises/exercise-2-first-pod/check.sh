#!/bin/bash

# Check script for Exercise 2: Your First Pod

echo "==== Checking Exercise 2: Your First Pod ===="

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

# Check if podinfo pod exists
if ! kubectl get pod podinfo &> /dev/null; then
    echo "❌ podinfo pod not found! Please create the pod first."
    echo "   Run: kubectl apply -f manifests/pod.yaml"
    exit 1
fi

echo "✅ podinfo pod found."

# Check pod status
POD_STATUS=$(kubectl get pod podinfo -o jsonpath='{.status.phase}')
if [ "$POD_STATUS" != "Running" ]; then
    echo "❌ podinfo pod is not running! Current status: $POD_STATUS"
    echo "   Check the pod status with: kubectl describe pod podinfo"
    exit 1
fi

echo "✅ podinfo pod is running."

# Check if container is ready
CONTAINER_READY=$(kubectl get pod podinfo -o jsonpath='{.status.containerStatuses[0].ready}')
if [ "$CONTAINER_READY" != "true" ]; then
    echo "❌ podinfo container is not ready!"
    echo "   Check the pod status with: kubectl describe pod podinfo"
    exit 1
fi

echo "✅ podinfo container is ready."

# Check if pod has the correct image
POD_IMAGE=$(kubectl get pod podinfo -o jsonpath='{.spec.containers[0].image}')
if [[ "$POD_IMAGE" != *"stefanprodan/podinfo"* ]]; then
    echo "❌ podinfo pod is not using the correct image! Current image: $POD_IMAGE"
    echo "   Expected an image from stefanprodan/podinfo"
    exit 1
fi

echo "✅ podinfo pod is using the correct image: $POD_IMAGE."

# Check if pod has resource limits set
MEMORY_LIMIT=$(kubectl get pod podinfo -o jsonpath='{.spec.containers[0].resources.limits.memory}')
CPU_LIMIT=$(kubectl get pod podinfo -o jsonpath='{.spec.containers[0].resources.limits.cpu}')

if [ -z "$MEMORY_LIMIT" ] || [ -z "$CPU_LIMIT" ]; then
    echo "❌ podinfo pod is missing resource limits!"
    exit 1
fi

echo "✅ podinfo pod has resource limits set: Memory=$MEMORY_LIMIT, CPU=$CPU_LIMIT."

# Check if pod has the correct port
POD_PORT=$(kubectl get pod podinfo -o jsonpath='{.spec.containers[0].ports[0].containerPort}')
if [ "$POD_PORT" != "9898" ]; then
    echo "❌ podinfo pod is not exposing the correct port! Current port: $POD_PORT"
    echo "   Expected port: 9898"
    exit 1
fi

echo "✅ podinfo pod is exposing the correct port: $POD_PORT."

# Check if pod has environment variables set
ENV_VARS_COUNT=$(kubectl get pod podinfo -o jsonpath='{.spec.containers[0].env}' | grep -o "name" | wc -l)
if [ "$ENV_VARS_COUNT" -lt 2 ]; then
    echo "❌ podinfo pod is missing environment variables!"
    exit 1
fi

echo "✅ podinfo pod has environment variables set."

# Check if pod has probes set
LIVENESS_PROBE=$(kubectl get pod podinfo -o jsonpath='{.spec.containers[0].livenessProbe}')
READINESS_PROBE=$(kubectl get pod podinfo -o jsonpath='{.spec.containers[0].readinessProbe}')

if [ -z "$LIVENESS_PROBE" ] || [ -z "$READINESS_PROBE" ]; then
    echo "❌ podinfo pod is missing health probes!"
    exit 1
fi

echo "✅ podinfo pod has health probes set."

# Attempt to access the pod via port-forward
echo "Testing pod accessibility via port-forward..."
PORT_FORWARD_PID=""

# Start port-forward in the background
kubectl port-forward pod/podinfo 8080:9898 &> /dev/null & 
PORT_FORWARD_PID=$!

# Wait for port-forward to start
sleep 5



# Check if port-forward is working
if ! curl -s http://localhost:8080/healthz &> /dev/null; then
    echo "❌ podinfo pod is not accessible via port-forward!"
    exit 1
fi


# Clean up port-forward
kill $PORT_FORWARD_PID &> /dev/null

echo "✅ podinfo pod is accessible via port-forward."



echo "✅ All checks passed!"
echo "You've successfully completed Exercise 2."
echo "Next steps:"
echo "1. Continue experimenting with Pods as suggested in the README.md"
echo "2. Try the challenges mentioned in the README.md"
echo "3. When ready, proceed to Exercise 3: ReplicaSets"
