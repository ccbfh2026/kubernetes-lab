# Exercise 7: DNS in Kubernetes

In this exercise, you will explore DNS resolution in Kubernetes, understand service discovery patterns, and learn how the cluster DNS service works.

## Goals

- Understand the Kubernetes DNS service (CoreDNS)
- Learn the DNS naming conventions for services and pods
- Explore DNS-based service discovery
- Troubleshoot DNS-related issues

## Background

Kubernetes provides a DNS cluster add-on that serves DNS records for Kubernetes services. Containers started by Kubernetes automatically include this DNS server in their DNS searches.

DNS naming conventions in Kubernetes:

- Services: `<service-name>.<namespace>.svc.cluster.local`
- Pods: `<pod-ip-with-dashes>.<namespace>.pod.cluster.local`

The Kubernetes DNS server is based on CoreDNS, a flexible and extensible DNS server that serves as a Kubernetes cluster DNS.

## Step 1: Deploy Test Services and Pods

First, let's create several services and pods to work with:

```bash
kubectl apply -f manifests/dns-testing.yaml
```

This command creates:

- Multiple services in different namespaces
- Pods with different configurations
- A headless service for direct pod DNS resolution

## Step 2: Explore Service DNS Records

Let's access one of our test pods to examine DNS records:

```bash
kubectl exec -it dns-test -n default -- /bin/bash
```

Inside the pod, use the DNS tools to investigate service records:

```bash
# Look up a service in the same namespace
nslookup simple-service

# Look up a service in another namespace
nslookup backend-service.dns-test

# Look up with fully qualified domain name
nslookup simple-service.default.svc.cluster.local
```

Notice that the service name alone will resolve within the same namespace, but you need to specify the namespace for services in other namespaces.

## Step 3: Understand DNS Record Types

Services in Kubernetes create different types of DNS records. Let's inspect them:

```bash
# A records (IPv4 addresses)
dig simple-service.default.svc.cluster.local A

# SRV records (service ports and hostnames)
dig _http._tcp.simple-service.default.svc.cluster.local SRV
```

SRV records are created for named ports that are part of a service.

## Step 4: Examine Pod DNS Resolution

For headless services (services without a cluster IP), Kubernetes provides DNS records for individual pods:

```bash
# First, get the pod IPs of the stateful pods
exit

kubectl get pods -n default -l app=stateful -o wide


# Look up the headless service
kubectl exec -it dns-test -n default -- /bin/bash

dig stateful-svc.default.svc.cluster.local

# Notice that it returns A records for each pod
```

## Step 5: Explore DNS Configuration

Let's look at how DNS is configured inside a Kubernetes pod:

```bash
# Check the DNS resolver configuration
cat /etc/resolv.conf

# Look for the nameserver (typically 10.96.0.10 or similar)
# Notice the search domains that allow shortening of DNS names
```

The `search` line in `/etc/resolv.conf` is what allows pods to use shortened service names.

## Step 6: Test External DNS Resolution

Kubernetes pods can also resolve external domain names:

```bash
# Try to resolve an external domain
nslookup kubernetes.io

# Check that external services work
curl -I https://kubernetes.io
```

## Step 7: Understand the CoreDNS Configuration

CoreDNS is the default DNS solution for Kubernetes. Let's see how it's configured:

```bash
# Exit the test pod
exit

# View the CoreDNS ConfigMap
kubectl get configmap coredns -n kube-system -o yaml
```

The ConfigMap contains a file called `Corefile` that configures how CoreDNS operates.

## Step 8: Create a Custom DNS Entry using ConfigMap

Let's create a ConfigMap with a custom entry that will be mounted to a pod:

```bash
kubectl apply -f manifests/custom-hosts.yaml
```

This creates a pod with a customized `/etc/hosts` file:

```bash
kubectl exec -it custom-dns -n default -- cat /etc/hosts
# The following ping will fail because the IP is not reachable, but you will see that it resolves the custom host
kubectl exec -it custom-dns -n default -- ping custom-host
```

## Step 9: Run the check.sh script

Verify your work:

```bash
./check.sh
```

## Cleanup

```bash
kubectl delete -f manifests/dns-testing.yaml
kubectl delete -f manifests/custom-hosts.yaml
```

## Challenges

1. Create a pod with a custom DNS configuration using the `dnsConfig` field
2. Set up a pod that uses the host's DNS configuration instead of the cluster DNS
3. Demonstrate a DNS name collision by creating services with the same name in different namespaces, and show how the fully qualified domain name prevents ambiguity
