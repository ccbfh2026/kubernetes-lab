#!/bin/bash

# Setup script for Exercise 7: DNS in Kubernetes

echo "==== Setting up Exercise 7: DNS in Kubernetes ===="

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

# Create dns-testing.yaml manifest
echo "Creating DNS testing manifest file..."
cat > manifests/dns-testing.yaml << EOF
---
apiVersion: v1
kind: Namespace
metadata:
  name: dns-test
---
# Simple service in default namespace
apiVersion: v1
kind: Service
metadata:
  name: simple-service
  namespace: default
spec:
  selector:
    app: dns-test
  ports:
  - name: http
    port: 80
    targetPort: 8080
---
# Test pod in default namespace
apiVersion: v1
kind: Pod
metadata:
  name: dns-test
  namespace: default
  labels:
    app: dns-test
spec:
  containers:
  - name: dns-test
    image: nicolaka/netshoot
    command: 
      - sleep
      - "3600"
    resources:
      limits:
        memory: "128Mi"
        cpu: "100m"
---
# Service in different namespace
apiVersion: v1
kind: Service
metadata:
  name: backend-service
  namespace: dns-test
spec:
  selector:
    app: backend
  ports:
  - port: 8080
    targetPort: 8080
---
# Pod in different namespace
apiVersion: v1
kind: Pod
metadata:
  name: backend-pod
  namespace: dns-test
  labels:
    app: backend
spec:
  containers:
  - name: backend
    image: nicolaka/netshoot
    command: 
      - sleep
      - "3600"
    resources:
      limits:
        memory: "128Mi"
        cpu: "100m"
---
# StatefulSet with headless service for DNS testing
apiVersion: v1
kind: Service
metadata:
  name: stateful-svc
  namespace: default
spec:
  clusterIP: None  # Headless service
  selector:
    app: stateful
  ports:
  - port: 80
    targetPort: 8080
---
apiVersion: apps/v1
kind: StatefulSet
metadata:
  name: stateful-app
  namespace: default
spec:
  serviceName: "stateful-svc"
  replicas: 3
  selector:
    matchLabels:
      app: stateful
  template:
    metadata:
      labels:
        app: stateful
    spec:
      containers:
      - name: stateful
        image: nicolaka/netshoot
        command: 
          - sleep
          - "3600"
        resources:
          limits:
            memory: "128Mi"
            cpu: "100m"
EOF

# Create custom-hosts.yaml manifest
echo "Creating custom hosts manifest file..."
cat > manifests/custom-hosts.yaml << EOF
---
# ConfigMap with custom hosts entries
apiVersion: v1
kind: ConfigMap
metadata:
  name: custom-hosts
  namespace: default
data:
  hosts: |
    # Custom hosts entries
    127.0.0.1 localhost
    ::1 localhost
    
    # Custom entries for testing
    192.168.1.100 custom-host
    192.168.1.101 another-custom-host
---
# Pod that mounts the custom hosts file
apiVersion: v1
kind: Pod
metadata:
  name: custom-dns
  namespace: default
spec:
  containers:
  - name: custom-dns
    image: nicolaka/netshoot
    command: 
      - sleep
      - "3600"
    resources:
      limits:
        memory: "128Mi"
        cpu: "100m"
    volumeMounts:
    - name: hosts-volume
      mountPath: /etc/hosts
      subPath: hosts
  volumes:
  - name: hosts-volume
    configMap:
      name: custom-hosts
EOF

# Clean up existing resources if they exist
if kubectl get namespace dns-test &> /dev/null; then
    echo "Found existing namespace dns-test. Deleting it..."
    kubectl delete namespace dns-test
    
    # Wait for namespace to be deleted
    while kubectl get namespace dns-test &> /dev/null; do
        echo "Waiting for namespace dns-test to be deleted..."
        sleep 2
    done
    echo "✅ Existing namespace dns-test deleted."
fi

# Check if pods and services exist in default namespace and delete if they do
for resource in "pod/dns-test" "service/simple-service" "service/stateful-svc" "statefulset/stateful-app" "pod/custom-dns" "configmap/custom-hosts"; do
    if kubectl get $resource -n default &> /dev/null; then
        echo "Found existing $resource. Deleting it..."
        kubectl delete $resource -n default
        
        # Wait for resource to be deleted
        while kubectl get $resource -n default &> /dev/null; do
            echo "Waiting for $resource to be deleted..."
            sleep 2
        done
        echo "✅ Existing $resource deleted."
    fi
done

echo ""
echo "==== Setup Complete! ===="
echo "You're now ready to start Exercise 7."
echo ""
echo "Next steps:"
echo "1. Review the DNS testing manifests in the manifests directory"
echo "2. Deploy the DNS testing environment using: kubectl apply -f manifests/dns-testing.yaml"
echo "3. Follow the instructions in the README.md file"
echo ""

# Provide information about CoreDNS
if kubectl get -n kube-system deployment coredns &> /dev/null; then
    DNS_PODS=$(kubectl get pods -n kube-system -l k8s-app=kube-dns -o name | wc -l)
    if [ "$DNS_PODS" -gt 0 ]; then
        echo "Your cluster is running CoreDNS with $DNS_PODS pod(s)."
        DNS_SERVICE_IP=$(kubectl get service -n kube-system kube-dns -o jsonpath='{.spec.clusterIP}')
        if [ -n "$DNS_SERVICE_IP" ]; then
            echo "CoreDNS service IP: $DNS_SERVICE_IP"
        fi
    else
        echo "CoreDNS pods not found. Your cluster might be using a different DNS provider."
    fi
else
    echo "CoreDNS deployment not found. Your cluster might be using a different DNS provider."
fi
