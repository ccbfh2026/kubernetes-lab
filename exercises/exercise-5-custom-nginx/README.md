# Exercise 5: Custom Nginx Deployment

This exercise will guide you through creating a custom Nginx Docker image, deploying it to your Kubernetes cluster, and exposing it for access.

## Goals

- Build a custom Docker image based on Nginx
- Push the image to a registry (or use it locally)
- Deploy the custom Nginx container to Kubernetes
- Expose the Nginx service
- Access your custom webpage

## Prerequisites

- Completed Exercise 1 (Environment Setup)
- Docker installed and running
- KIND cluster running
- kubectl configured to use your cluster

## Step 1: Understanding the Dockerfile

In this exercise, we have a simple Dockerfile that:

1. Uses the official Nginx Alpine image as base
2. Copies a custom index.html file into the container
3. Exposes port 80 (default HTTP port)

Review the Dockerfile in this directory to understand its structure.

## Step 2: Building Your Custom Image

To build your Docker image:

```bash
# Build the image
docker build -t custom-nginx:v1 .
```

## Step 3: Loading the Image into KIND

Since we're using KIND, we need to load the image into our cluster:

```bash
# Load the image into your KIND cluster
kind load docker-image custom-nginx:v1 --name k8s-intro
```

## Step 4: Creating a Deployment

The deployment manifest is provided in the `manifests` directory as `nginx-deployment.yaml`. Review it to understand how it:

1. Defines a deployment with a specified number of replicas
2. Uses the custom image you built
3. Sets up basic resource requests and limits

Apply the deployment:

```bash
kubectl apply -f manifests/nginx-deployment.yaml
```

## Step 5: Creating a Service

To expose your Nginx deployment, we need to create a Service. The service manifest is provided in `manifests/nginx-service.yaml`.

Apply the service:

```bash
kubectl apply -f manifests/nginx-service.yaml
```

## Step 6: Accessing Your Custom Nginx

To access your custom Nginx webpage, use port-forwarding:

```bash
kubectl port-forward svc/custom-nginx 8080:80
```

Now, open your browser and navigate to <http://localhost:8080>

You should see your custom webpage.

## Understanding Services in Kubernetes

Services in Kubernetes provide:

1. A stable IP address for pods
2. Load balancing across pods with the same labels
3. Service discovery within the cluster
4. Potential external access points

Types of Services:

- **ClusterIP**: Internal only (default)
- **NodePort**: Exposes the service on each Node's IP at a static port
- **LoadBalancer**: Exposes the service externally using a cloud provider's load balancer
- **ExternalName**: Maps the service to a DNS name

## Challenges

1. **Custom Configuration**: Modify the Dockerfile to include a custom nginx.conf file
2. **Multiple Pages**: Add more HTML pages and update the Nginx configuration to serve them
3. **Health Checks**: Add readiness and liveness probes to your deployment
4. **Scaling**: Scale your deployment to 3 replicas and observe the load balancing
5. **Ingress**: If you're feeling ambitious, install an Ingress controller and create an Ingress resource for your Nginx service

## Further Reading

- [Nginx Official Documentation](https://nginx.org/en/docs/)
- [Kubernetes Services Documentation](https://kubernetes.io/docs/concepts/services-networking/service/)
- [Kubernetes Deployments Documentation](https://kubernetes.io/docs/concepts/workloads/controllers/deployment/)
- [Dockerfile Best Practices](https://docs.docker.com/develop/develop-images/dockerfile_best-practices/)
