#!/bin/bash

# Check script for Exercise 3: Working with ReplicaSets

echo "==== Checking Exercise 3: Working with ReplicaSets ===="

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

# Check if podinfo-rs replicaset exists
if ! kubectl get replicaset podinfo-rs &> /dev/null; then
    echo "❌ podinfo-rs replicaset not found! Please create the replicaset first."
    echo "   Run: kubectl apply -f manifests/replicaset.yaml"
    exit 1
fi

echo "✅ podinfo-rs replicaset found."

# Check replicaset status
DESIRED_REPLICAS=$(kubectl get replicaset podinfo-rs -o jsonpath='{.spec.replicas}')
CURRENT_REPLICAS=$(kubectl get replicaset podinfo-rs -o jsonpath='{.status.replicas}')
READY_REPLICAS=$(kubectl get replicaset podinfo-rs -o jsonpath='{.status.readyReplicas}')

if [[ -z "$READY_REPLICAS" || "$READY_REPLICAS" -lt "$DESIRED_REPLICAS" ]]; then
    echo "❌ Not all desired pods are ready! Desired: $DESIRED_REPLICAS, Ready: $READY_REPLICAS"
    echo "   Check the replicaset status with: kubectl describe replicaset podinfo-rs"
    exit 1
fi

echo "✅ ReplicaSet has $READY_REPLICAS/$DESIRED_REPLICAS pods ready."

# Check if selector matches pod labels
SELECTOR=$(kubectl get replicaset podinfo-rs -o jsonpath='{.spec.selector.matchLabels.app}')
POD_LABELS=$(kubectl get pods -l app=podinfo -o jsonpath='{.items[0].metadata.labels.app}')

if [ "$SELECTOR" != "$POD_LABELS" ]; then
    echo "❌ ReplicaSet selector doesn't match pod labels!"
    echo "   Selector: app=$SELECTOR, Pod Label: app=$POD_LABELS"
    exit 1
fi

echo "✅ ReplicaSet selector correctly matches pod labels."

# Check if pods are using the correct image
POD_IMAGE=$(kubectl get pods -l app=podinfo -o jsonpath='{.items[0].spec.containers[0].image}')
if [[ "$POD_IMAGE" != *"stefanprodan/podinfo"* ]]; then
    echo "❌ Pods are not using the correct image! Current image: $POD_IMAGE"
    echo "   Expected an image from stefanprodan/podinfo"
    exit 1
fi

echo "✅ Pods are using the correct image: $POD_IMAGE."

# Test self-healing by deleting a pod
echo "Testing self-healing capability..."
POD_TO_DELETE=$(kubectl get pods -l app=podinfo -o jsonpath='{.items[0].metadata.name}')
echo "Deleting pod $POD_TO_DELETE..."
kubectl delete pod $POD_TO_DELETE

# Wait for replacement pod
sleep 5
NEW_POD_COUNT=$(kubectl get pods -l app=podinfo | grep -c Running)
if [ "$NEW_POD_COUNT" -ne "$DESIRED_REPLICAS" ]; then
    echo "❌ ReplicaSet failed to replace the deleted pod!"
    echo "   Expected $DESIRED_REPLICAS pods, found $NEW_POD_COUNT"
    exit 1
fi

echo "✅ ReplicaSet successfully replaced the deleted pod."

# Test scaling
echo "Testing scaling capability..."
SCALE_TO=$((DESIRED_REPLICAS + 2))
echo "Scaling ReplicaSet to $SCALE_TO replicas..."
kubectl scale replicaset podinfo-rs --replicas=$SCALE_TO

# Wait for scaling
sleep 10
SCALED_POD_COUNT=$(kubectl get pods -l app=podinfo | grep -c Running)
if [ "$SCALED_POD_COUNT" -ne "$SCALE_TO" ]; then
    echo "❌ ReplicaSet failed to scale to $SCALE_TO replicas!"
    echo "   Expected $SCALE_TO pods, found $SCALED_POD_COUNT"
    exit 1
fi

echo "✅ ReplicaSet successfully scaled to $SCALE_TO replicas."

# Scale back to original
echo "Scaling back to original $DESIRED_REPLICAS replicas..."
kubectl scale replicaset podinfo-rs --replicas=$DESIRED_REPLICAS

echo ""
echo "==== All checks passed! ===="
echo "Your ReplicaSet is working correctly."
echo ""
echo "Next steps:"
echo "1. Continue experimenting with ReplicaSets as suggested in the README.md"
echo "2. Try the challenges mentioned in the README.md"
echo "3. When ready, proceed to Exercise 4: Deployments"
echo ""
