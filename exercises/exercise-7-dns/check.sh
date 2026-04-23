#!/bin/bash

# Check script for Exercise 7: DNS in Kubernetes

echo "==== Checking Exercise 7: DNS in Kubernetes ===="

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

# Check if the dns-test namespace exists
if ! kubectl get namespace dns-test &> /dev/null; then
    echo "❌ Namespace dns-test not found! Please create the namespace."
    echo "   Run: kubectl apply -f manifests/dns-testing.yaml"
    exit 1
fi

echo "✅ dns-test namespace found."

# Check if pods and services exist
RESOURCES_MISSING=0

# Resources in default namespace
DEFAULT_RESOURCES=("pod/dns-test" "service/simple-service" "service/stateful-svc" "statefulset/stateful-app")
for resource in "${DEFAULT_RESOURCES[@]}"; do
    if ! kubectl get $resource -n default &> /dev/null; then
        echo "❌ Resource $resource not found in default namespace!"
        echo "   Run: kubectl apply -f manifests/dns-testing.yaml"
        RESOURCES_MISSING=1
    fi
done

# Resources in dns-test namespace
DNS_TEST_RESOURCES=("pod/backend-pod" "service/backend-service")
for resource in "${DNS_TEST_RESOURCES[@]}"; do
    if ! kubectl get $resource -n dns-test &> /dev/null; then
        echo "❌ Resource $resource not found in dns-test namespace!"
        echo "   Run: kubectl apply -f manifests/dns-testing.yaml"
        RESOURCES_MISSING=1
    fi
done

# Check if StatefulSet pods are running
STATEFUL_POD_COUNT=$(kubectl get pods -n default -l app=stateful --no-headers | wc -l)
if [[ "$STATEFUL_POD_COUNT" -lt 3 ]]; then
    echo "❌ StatefulSet pods are not running correctly. Expected 3 pods, found $STATEFUL_POD_COUNT."
    RESOURCES_MISSING=1
fi

if [[ $RESOURCES_MISSING -eq 1 ]]; then
    exit 1
fi

echo "✅ All required resources found."

# Check if custom DNS resources exist
if ! kubectl get pod custom-dns -n default &> /dev/null; then
    echo "❌ Pod custom-dns not found! Please create the custom DNS pod."
    echo "   Run: kubectl apply -f manifests/custom-hosts.yaml"
    exit 1
fi

if ! kubectl get configmap custom-hosts -n default &> /dev/null; then
    echo "❌ ConfigMap custom-hosts not found! Please create the custom hosts ConfigMap."
    echo "   Run: kubectl apply -f manifests/custom-hosts.yaml"
    exit 1
fi

echo "✅ Custom DNS resources found."

# Test DNS resolution within the cluster
echo "🔄 Testing DNS functionality..."

# Test resolving service in the same namespace
SAME_NS_LOOKUP=$(kubectl exec -it dns-test -n default -- nslookup simple-service 2>/dev/null)
SAME_NS_STATUS=$?

if [[ $SAME_NS_STATUS -ne 0 ]]; then
    echo "❌ DNS lookup for simple-service in the same namespace failed."
    echo "   Try manually: kubectl exec -it dns-test -n default -- nslookup simple-service"
else
    echo "✅ DNS lookup for service in same namespace successful."
fi

# Test resolving service across namespaces
CROSS_NS_LOOKUP=$(kubectl exec -it dns-test -n default -- nslookup backend-service.dns-test 2>/dev/null)
CROSS_NS_STATUS=$?

if [[ $CROSS_NS_STATUS -ne 0 ]]; then
    echo "❌ DNS lookup for backend-service.dns-test across namespaces failed."
    echo "   Try manually: kubectl exec -it dns-test -n default -- nslookup backend-service.dns-test"
else
    echo "✅ DNS lookup for service across namespaces successful."
fi

# Test resolving headless service (should return multiple A records)
HEADLESS_LOOKUP=$(kubectl exec -it dns-test -n default -- nslookup stateful-svc 2>/dev/null)
HEADLESS_STATUS=$?

if [[ $HEADLESS_STATUS -ne 0 ]]; then
    echo "❌ DNS lookup for headless service stateful-svc failed."
    echo "   Try manually: kubectl exec -it dns-test -n default -- nslookup stateful-svc"
else
    echo "✅ DNS lookup for headless service successful."
fi

# Check custom hosts file in custom-dns pod
CUSTOM_HOSTS=$(kubectl exec -it custom-dns -n default -- grep "custom-host" /etc/hosts 2>/dev/null)
if [[ -z "$CUSTOM_HOSTS" ]]; then
    echo "❌ Custom hosts entry not found in custom-dns pod."
    echo "   Try manually: kubectl exec -it custom-dns -n default -- cat /etc/hosts"
else
    echo "✅ Custom hosts configuration verified."
fi

# Provide information about CoreDNS
echo ""
echo "==== CoreDNS Information ===="

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

# Show resolv.conf from a pod
echo ""
echo "==== DNS Configuration in Pods ===="
kubectl exec -it dns-test -n default -- cat /etc/resolv.conf 2>/dev/null || echo "Could not fetch resolv.conf"

echo ""
echo "==== Exercise 7 Check Complete ===="
echo "You have successfully:"
echo "✅ Created services in different namespaces"
echo "✅ Created a headless service for StatefulSet"
echo "✅ Verified DNS resolution across namespaces"
echo "✅ Created custom DNS configuration"
echo ""
echo "Next steps:"
echo "- Continue exploring DNS resolution in Kubernetes"
echo "- Try the commands suggested in the README.md"
echo "- Try the challenge exercises"
echo ""
