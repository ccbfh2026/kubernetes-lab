# Exercise 2: Your First Pod

In this exercise, you will learn how to create and manage a basic Kubernetes Pod using the podinfo image.

## Goals

- Understand what a Pod is and its role in Kubernetes
- Create a Pod using YAML manifests
- Interact with the Pod using kubectl commands
- Access the Pod's application
- Learn troubleshooting techniques for Pods

## Background

A Pod is the smallest deployable unit in Kubernetes. It represents a single instance of a running process in your cluster. Pods contain one or more containers (like Docker containers) that are guaranteed to be co-located on the same host machine and can share resources.

For this exercise, we'll use [podinfo](https://github.com/stefanprodan/podinfo), a lightweight web application that showcases the hostname, version and other metadata.

## Step 1: Examine the Pod Manifest

Review the provided `pod.yaml` file in the `manifests` directory:

```yaml
apiVersion: v1
kind: Pod
metadata:
  name: podinfo
  labels:
    app: podinfo
spec:
  containers:
  - name: podinfo
    image: stefanprodan/podinfo:6.7.1
    ports:
    - containerPort: 9898
      name: http
    resources:
      requests:
        memory: "32Mi"
        cpu: "100m"
      limits:
        memory: "128Mi"
        cpu: "500m"
    env:
    - name: KUBERNETES_NAMESPACE
      valueFrom:
        fieldRef:
          fieldPath: metadata.namespace
    - name: KUBERNETES_POD_NAME
      valueFrom:
        fieldRef:
          fieldPath: metadata.name
    livenessProbe:
      httpGet:
        path: /healthz
        port: 9898
    readinessProbe:
      httpGet:
        path: /readyz
        port: 9898
```

## Step 2: Create the Pod

Apply the manifest to create your first Pod:

```bash
kubectl apply -f manifests/pod.yaml
```

## Step 3: Verify the Pod Status

Check that your Pod is running:

```bash
kubectl get pods
```

You should see output similar to:

```bash
NAME      READY   STATUS    RESTARTS   AGE
podinfo   1/1     Running   0          10s
```

## Step 4: Get Detailed Information about the Pod

Retrieve detailed information about your Pod:

```bash
kubectl describe pod podinfo
```

This command shows you detailed information including:

- Pod details and status
- Container information
- Events related to the Pod
- Resource limits
- Volume information

## Step 5: Access the Pod Application

Forward a local port to the Pod to access the application:

```bash
kubectl port-forward pod/podinfo 8080:9898
```

Now open your web browser and navigate to <http://localhost:8080> to see the podinfo application.

## Step 6: View the Pod Logs

Check the logs of your running Pod:

```bash
kubectl logs podinfo
```

Add `-f` flag to follow the logs in real-time:

```bash
kubectl logs -f podinfo
```

Press Ctrl+C to exit the log stream.

## Step 7: Execute Commands Inside the Pod

Run a command inside the running container:

```bash
kubectl exec -it podinfo -- /bin/sh
```

Inside the container, you can explore the filesystem and run commands:

```bash
# Get hostname
hostname

# Check environment variables
env

# Check the process list
ps aux

# Exit the shell
exit
```

## Step 7.1: Run the `check.sh` script

Run the `check.sh` script to verify the pod is running correctly:

```bash
./check.sh
```

## Step 8: Delete the Pod

Clean up by deleting the Pod:

```bash
kubectl delete pod podinfo
```

Alternatively, you can delete using the manifest file:

```bash
kubectl delete -f manifests/pod.yaml
```

## Challenges and Additional Exercises

1. **Multiple Containers**: Modify the Pod manifest to include a second container (such as nginx) in the same Pod. Make sure both containers are running correctly.

2. **Custom Environment Variables**: Add custom environment variables to the podinfo container and verify they are set correctly by checking the application's `/env` endpoint.

3. **Resource Investigation**: Experiment with different resource limits and requests. What happens if you set very low limits? How does this affect the Pod's performance?

4. **Init Container**: Add an init container to the Pod that creates a file, then have the main container check for this file's existence.

## Troubleshooting Guide

### Common Pod Issues

1. **Pod is in "Pending" state**
   - Insufficient cluster resources
   - PersistentVolumeClaim is pending
   - Node selector cannot be satisfied

   Resolution: Check event logs with `kubectl describe pod <pod-name>`

2. **Pod is in "CrashLoopBackOff" state**
   - Application is crashing
   - Liveness probe failures
   - Resource constraints

   Resolution: Check logs with `kubectl logs <pod-name>` and fix application issues

3. **Pod is in "ImagePullBackOff" state**
   - Image doesn't exist
   - Image repository requires authentication
   - Network issues

   Resolution: Verify image name, add image pull secrets if needed

4. **Container fails to start**
   - Command or arguments are incorrect
   - Container entrypoint has errors

   Resolution: Check container logs and fix startup command

## Next Steps

When you're ready, proceed to [Exercise 3: Working with ReplicaSets](../exercise-3-replicaset/) to learn how to manage multiple identical Pods using ReplicaSets.
