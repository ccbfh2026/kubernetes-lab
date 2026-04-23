# Exercise 6: Kubernetes Services

In this exercise, you will learn about Kubernetes Services, which are used to expose your applications running on a set of Pods as network services.

## Goals

- Understand different Service types in Kubernetes
- Create and use ClusterIP services for internal communication
- Expose applications using NodePort services
- Experience how services provide stable endpoints for pods

## Background

Services in Kubernetes provide an abstraction that defines a logical set of Pods and a policy to access them. As Pods are ephemeral (they can be created and destroyed dynamically), Services provide a stable endpoint for other applications to connect to, regardless of which specific Pod is serving the request.

The key Service types you'll work with are:

- **ClusterIP**: Exposes the Service on an internal IP in the cluster. This type makes the Service only reachable from within the cluster.
- **NodePort**: Exposes the Service on each Node's IP at a static port. A ClusterIP Service is automatically created.
- **LoadBalancer**: Exposes the Service externally using a cloud provider's load balancer.
- **ExternalName**: Maps the Service to the contents of the `externalName` field (e.g., `foo.bar.example.com`).

## Step 1: Create a Simple Deployment

First, let's create a deployment that we'll use throughout this exercise:

```bash
kubectl apply -f manifests/hello-deployment.yaml
```

This will create three replicas of a simple HTTP server that responds with "Hello, Kubernetes!".

## Step 2: Create a ClusterIP Service

A ClusterIP service provides a stable internal IP address for pod-to-pod communication:

```bash
kubectl apply -f manifests/clusterip-service.yaml
```

Verify the service is created:

```bash
kubectl get services
```

You should see your new service with a cluster IP address.

## Step 3: Test Internal Communication

Let's create a temporary pod to test communication with our service:

```bash
kubectl run tmp-shell --rm -i --tty --image nicolaka/netshoot -- /bin/bash
```

Inside the pod, use curl to connect to the service:

```bash
curl hello-service:8080
```

You should see a JSON response that includes the pod's hostname, version, and other details. Run the command multiple times to see load balancing in action - you'll notice different pod names in the response as the service routes requests to different pods.

For a cleaner output, you can use jq to just see the hostname:

```bash
curl -s hello-service:8080 | grep hostname
```

You can also visit specific endpoints provided by podinfo:

```bash
# Get version information
curl hello-service:8080/version

# Get pod details
curl hello-service:8080/env

# Get a random number
curl hello-service:8080/rand
```

Exit the temporary pod when finished:

```bash
exit
```

## Step 4: Create a NodePort Service

Now, let's expose our application outside the cluster using a NodePort service:

```bash
kubectl apply -f manifests/nodeport-service.yaml
```

Check the service details:

```bash
kubectl get services hello-nodeport
```

Note the assigned NodePort (a port in the 30000-32767 range).

## Step 5: Access the Service

### For KIND clusters

When using KIND (Kubernetes IN Docker), accessing NodePorts requires special handling, especially in multi-node setups.

The simplest and most reliable approach is to use port-forwarding:

```bash
kubectl port-forward service/hello-nodeport 8080:8080
```

Then in another terminal:

```bash
curl localhost:8080
```

#### For KIND clusters with extraPortMappings

If your KIND cluster was created with `extraPortMappings` in the configuration (like in Exercise 1), you may be able to access NodePorts directly if they match the configured mappings.

Check your KIND configuration:

```bash
cat ../exercise-1-setup/kind-config.yaml
```

In this exercise, we've configured the NodePort service to use port 30000, which should be mapped in your KIND configuration. You can access it directly:

```bash
curl localhost:30000
```

### For other Kubernetes setups

Use the IP of any node in your cluster:

```bash
# Get the IP of one of your nodes
NODE_IP=$(kubectl get nodes -o jsonpath='{.items[0].status.addresses[0].address}')

# Access the service
curl $NODE_IP:30000
```

## Step 6: Service Discovery with DNS

Kubernetes provides a DNS service that allows pods to find services by name:

```bash
# Create a temporary pod to test DNS resolution
kubectl run dns-test --rm -i --tty --image nicolaka/netshoot -- /bin/bash

# Inside the pod, use nslookup to verify the service DNS entry
nslookup hello-service
nslookup hello-service.default.svc.cluster.local

# Use curl with the fully-qualified domain name
curl hello-service.default.svc.cluster.local:8080

# Exit the shell
exit
```

## Step 7: Observe Service Endpoints

Services route traffic to Pods through endpoints:

```bash
kubectl get endpoints hello-service
```

Scale the deployment and observe how the endpoints change:

```bash
kubectl scale deployment hello-deployment --replicas=5
kubectl get endpoints hello-service
```

## Step 8: Run the check.sh script

Verify your work:

```bash
./check.sh
```

## Cleanup

To remove the resources created in this exercise:

```bash
kubectl delete service hello-service
kubectl delete service hello-nodeport
kubectl delete deployment hello-deployment
```

## Challenges

1. Create a service with multiple port definitions (hint: look at the `ports` array in the service manifest)
2. Create a service for a different namespace and test cross-namespace communication
3. Create a headless service (ClusterIP: None) and observe how DNS returns all Pod IPs
