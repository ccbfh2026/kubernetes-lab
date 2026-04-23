# Exercise 1: Environment Setup

This exercise will guide you through setting up a complete local Kubernetes development environment.

## Goals

- Install Docker
- Install kubectl
- Set up a KIND (Kubernetes IN Docker) cluster
- Install a Kubernetes UI tool (k9s or Lens)
- Verify your environment is working properly

## Required Tools

### Docker

Docker is required to run containers locally and serves as the foundation for KIND.

**Official Documentation:** [Install Docker Engine](https://docs.docker.com/engine/install/)

### kubectl

kubectl is the command-line tool for interacting with Kubernetes clusters.

**Official Documentation:** [Install kubectl](https://kubernetes.io/docs/tasks/tools/install-kubectl/)

### KIND (Kubernetes IN Docker)

KIND allows you to run Kubernetes clusters inside Docker containers.

**Official Documentation:** [KIND Quick Start Guide](https://kind.sigs.k8s.io/docs/user/quick-start/)

### Kubernetes UI Tools (Optional)

Choose one of the following tools to help visualize and manage your Kubernetes resources:

- **k9s:** A terminal-based UI for Kubernetes
  - [k9s Installation](https://k9scli.io/topics/install/)

- **Lens:** A desktop application for Kubernetes
  - [Lens Download Page](https://k8slens.dev/)

## Creating a KIND Cluster

Once you have Docker and KIND installed, you can create a cluster using the following configuration:

Save this as `kind-config.yaml`:

```yaml
kind: Cluster
apiVersion: kind.x-k8s.io/v1alpha4
nodes:
- role: control-plane
  extraPortMappings:
  - containerPort: 30000
    hostPort: 30000
    listenAddress: "0.0.0.0"
    protocol: TCP
- role: worker
- role: worker
```

Create the cluster:

```bash
kind create cluster --name k8s-intro --config kind-config.yaml
```

## Verifying Your Environment

Run the following commands to ensure everything is set up correctly:

```bash
# Check Docker
docker ps

# Check kubectl and cluster connection
kubectl get nodes
kubectl get namespaces

# Start k9s to view your cluster (if installed)
k9s
```

If using Lens, open the application and add your cluster.

## Troubleshooting

For detailed troubleshooting steps, please refer to the official documentation for each tool:

- [Docker Troubleshooting](https://docs.docker.com/engine/troubleshoot/)
- [kubectl Troubleshooting](https://kubernetes.io/docs/tasks/debug/debug-cluster/troubleshooting/)
- [KIND Troubleshooting](https://kind.sigs.k8s.io/docs/user/known-issues/)

## Next Steps

Once your environment is set up, proceed to [Exercise 2: Your First Pod](../exercise-2-first-pod/).
