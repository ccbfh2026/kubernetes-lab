# Exercise 4: Deployments and Updates

In this exercise, you will learn how Deployments manage ReplicaSets to provide declarative updates and rollbacks for your applications.

## Goals

- Understand what a Deployment is and how it builds on ReplicaSets
- Create a Deployment using YAML manifests
- Perform rolling updates to update your application
- Roll back to a previous version if needed
- Configure update strategies
- Monitor deployment status

## Background

A Deployment is a higher-level concept that manages ReplicaSets and provides declarative updates to applications. Deployments allow you to:

- Deploy a ReplicaSet
- Update Pods to a new container image
- Roll back to an earlier Deployment revision
- Scale a Deployment up or down
- Pause and resume a Deployment

The key advantage of Deployments over ReplicaSets is the ability to update Pods smoothly without downtime.

## Step 1: Examine the Deployment Manifest

Review the provided `deployment.yaml` file in the `manifests` directory:

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: podinfo
  labels:
    app: podinfo
spec:
  replicas: 3
  selector:
    matchLabels:
      app: podinfo
  strategy:
    rollingUpdate:
      maxSurge: 1
      maxUnavailable: 1
    type: RollingUpdate
  template:
    metadata:
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

## Step 2: Create the Deployment

Apply the manifest to create your Deployment:

```bash
kubectl apply -f manifests/deployment.yaml
```

## Step 3: Verify the Deployment Status

Check that your Deployment, its ReplicaSet, and Pods are created:

```bash
kubectl get deployments
kubectl get replicasets
kubectl get pods
```

You should see output similar to:

```bash
# Deployment
NAME      READY   UP-TO-DATE   AVAILABLE   AGE
podinfo   3/3     3            3           7s

# ReplicaSet
NAME                DESIRED   CURRENT   READY   AGE
podinfo-f657d44b7   3         3         3       7s

# Pods
NAME                      READY   STATUS    RESTARTS   AGE
podinfo-f657d44b7-226xz   1/1     Running   0          7s
podinfo-f657d44b7-lpts6   1/1     Running   0          7s
podinfo-f657d44b7-lwcw8   1/1     Running   0          7s
```

## Step 4: Get Detailed Information about the Deployment

Retrieve detailed information about your Deployment:

```bash
kubectl describe deployment podinfo
```

This command shows you detailed information including:

- Deployment details and status
- Update strategy
- Pod template
- Events related to the Deployment

## Step 5: Expose the Deployment

Create a Service to expose your Deployment:

```bash
kubectl expose deployment podinfo --type=ClusterIP --port=9898
```

Test access to your Service:

```bash
kubectl port-forward service/podinfo 8080:9898
```

Visit <http://localhost:8080> in your browser to view the application.
Try to refresh the page a few times to see the different versions of the application.

## Step 6: Perform a Rolling Update

Update the application version by changing the container image:

```bash
kubectl set image deployment/podinfo podinfo=stefanprodan/podinfo:6.3.6
```

Watch the rolling update in progress:

```bash
kubectl rollout status deployment/podinfo
```

In another terminal, run:

```bash
kubectl get pods -w
```

You'll see new Pods being created and old Pods being terminated gradually.

## Step 7: Examine the Update History

View the rollout history of the Deployment:

```bash
kubectl rollout history deployment/podinfo
```

Get details about a specific revision:

```bash
kubectl rollout history deployment/podinfo --revision=2
```

## Step 8: Roll Back to a Previous Version

If there's an issue with the new version, you can roll back:

```bash
kubectl rollout undo deployment/podinfo
```

To roll back to a specific revision:

```bash
kubectl rollout undo deployment/podinfo --to-revision=1
```

## Step 9: Configure Update Strategies

Edit the Deployment to modify its update strategy:

```bash
kubectl edit deployment podinfo
```

Change the `strategy` section to use a different update strategy, save and exit.
Make sure to remove the `rollingUpdate` section first, otherwise you will get an error.

```yaml
strategy:
  type: Recreate
```

Make another update to see the new strategy in action:

```bash
kubectl set image deployment/podinfo podinfo=stefanprodan/podinfo:6.7.0
```

## Step 10: Scale the Deployment

Scale up the Deployment to 5 replicas:

```bash
kubectl scale deployment podinfo --replicas=5
```

## Step 10.1: Run the `check.sh` script

Run the `check.sh` script to verify the pod is running correctly:

```bash
./check.sh
```

## Step 11: Delete the Deployment

Clean up by deleting the Deployment and Service:

```bash
kubectl delete service podinfo
kubectl delete deployment podinfo
```

Alternatively, you can delete using the manifest file:

```bash
kubectl delete -f manifests/deployment.yaml
```

## Challenges and Additional Exercises

1. **Custom Update Strategy**: Experiment with different `maxSurge` and `maxUnavailable` values in the rolling update strategy. How do they affect the update process?

2. **Blue/Green Deployment**: Implement a blue/green deployment using labels and a Service. Create two Deployments (blue and green) and switch traffic between them.

3. **Canary Deployment**: Implement a canary deployment by creating two Deployments with different versions and controlling traffic distribution using Services and labels.

4. **Failing Updates**: Intentionally update to a broken version and observe how readiness probes affect the rollout. Then practice rolling back.

5. **Pausing and Resuming**: Try pausing a deployment mid-update with `kubectl rollout pause`, observing the state, and then resuming with `kubectl rollout resume`.

## Troubleshooting Guide

### Common Deployment Issues

1. **Deployment stuck in progress**
   - Pod creation issues
   - Readiness probe failures
   - Resource constraints

   Resolution: Check Pod events and logs, verify readiness probe configuration

2. **Rollback fails**
   - History limit reached
   - Invalid revision number

   Resolution: Check rollout history and available revisions

3. **Update strategy issues**
   - Inappropriate strategy for application
   - Too many simultaneous updates causing service disruption

   Resolution: Adjust strategy parameters based on application requirements

## Next Steps

When you're ready, proceed to [Exercise 5: Custom Nginx Container](../exercise-5-custom-nginx/) to learn how to build a custom container and deploy it to Kubernetes.
