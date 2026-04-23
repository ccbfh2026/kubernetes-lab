#!/bin/bash

# Check script for Exercise 4: Deployments and Updates

echo "==== Checking Exercise 4: Deployments and Updates ===="

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

# Check if podinfo deployment exists
if ! kubectl get deployment podinfo &> /dev/null; then
    echo "❌ podinfo deployment not found! Please create the deployment first."
    echo "   Run: kubectl apply -f manifests/deployment.yaml"
    exit 1
fi

echo "✅ podinfo deployment found."

# Check deployment status
DESIRED_REPLICAS=$(kubectl get deployment podinfo -o jsonpath='{.spec.replicas}')
AVAILABLE_REPLICAS=$(kubectl get deployment podinfo -o jsonpath='{.status.availableReplicas}')
UP_TO_DATE_REPLICAS=$(kubectl get deployment podinfo -o jsonpath='{.status.updatedReplicas}')

if [[ -z "$AVAILABLE_REPLICAS" || "$AVAILABLE_REPLICAS" -lt "$DESIRED_REPLICAS" ]]; then
    echo "❌ Not all desired pods are available! Desired: $DESIRED_REPLICAS, Available: $AVAILABLE_REPLICAS"
    echo "   Check the deployment status with: kubectl describe deployment podinfo"
    exit 1
fi

if [[ -z "$UP_TO_DATE_REPLICAS" || "$UP_TO_DATE_REPLICAS" -lt "$DESIRED_REPLICAS" ]]; then
    echo "❌ Not all pods are up-to-date! Desired: $DESIRED_REPLICAS, Up-to-date: $UP_TO_DATE_REPLICAS"
    echo "   Check the deployment status with: kubectl describe deployment podinfo"
    exit 1
fi

echo "✅ Deployment has $AVAILABLE_REPLICAS/$DESIRED_REPLICAS pods available and up-to-date."

# Check if service exists
if ! kubectl get service podinfo &> /dev/null; then
    echo "⚠️ podinfo service not found. Have you exposed the deployment?"
    echo "   Run: kubectl expose deployment podinfo --type=ClusterIP --port=9898"
fi

# Check deployment rollout history
ROLLOUT_HISTORY=$(kubectl rollout history deployment/podinfo 2>/dev/null)
if [ $? -ne 0 ] || [[ -z "$ROLLOUT_HISTORY" ]]; then
    echo "❌ Failed to get deployment rollout history!"
    exit 1
fi

REVISION_COUNT=$(echo "$ROLLOUT_HISTORY" | wc -l)
if [ "$REVISION_COUNT" -lt 2 ]; then
    echo "❌ Deployment rollout history is empty! Expected at least 2 revisions."
    exit 1
fi

echo "✅ Deployment rollout history check passed."
