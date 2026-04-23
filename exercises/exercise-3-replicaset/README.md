# Exercise 3: Working with ReplicaSets

In this exercise, you will learn how ReplicaSets manage multiple identical Pods and provide self-healing capabilities in Kubernetes.

## Goals

- Understand what a ReplicaSet is and how it differs from a Pod
- Create a ReplicaSet using YAML manifests
- Observe how a ReplicaSet maintains the desired number of replicas
- Test the self-healing capabilities of a ReplicaSet
- Scale a ReplicaSet up and down

## Background

A ReplicaSet ensures that a specified number of Pod replicas are running at any given time. It allows you to:

- Specify the desired number of identical Pods
- Ensure Pods are replaced if they fail, are deleted, or are terminated
- Scale the number of Pods up or down easily

ReplicaSets use a selector to identify which Pods they can acquire.

## Step 1: Examine the ReplicaSet Manifest

Review the provided `replicaset.yaml` file in the `manifests` directory:

```yaml
apiVersion: apps/v1
kind: ReplicaSet
metadata:
  name: podinfo-rs
  labels:
    app: podinfo
spec:
  replicas: 3
  selector:
    matchLabels:
      app: podinfo
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

## Step 2: Create the ReplicaSet

Apply the manifest to create your ReplicaSet:

```bash
kubectl apply -f manifests/replicaset.yaml
```

## Step 3: Verify the ReplicaSet Status

Check that your ReplicaSet is created and its Pods are running:

```bash
kubectl get replicasets
kubectl get pods
```

You should see output similar to:

```bash
NAME         DESIRED   CURRENT   READY   AGE
podinfo-rs   3         3         3       30s
```

And for the pods:

```bash
NAME               READY   STATUS    RESTARTS   AGE
podinfo-rs-abcd1   1/1     Running   0          30s
podinfo-rs-abcd2   1/1     Running   0          30s
podinfo-rs-abcd3   1/1     Running   0          30s
```

## Step 4: Get Detailed Information about the ReplicaSet

Retrieve detailed information about your ReplicaSet:

```bash
kubectl describe replicaset podinfo-rs
```

This command shows you detailed information including:

- ReplicaSet details and status
- Pod template
- Events related to the ReplicaSet
- Selector information

## Step 5: Test Self-Healing

Delete one of the Pods managed by the ReplicaSet:

```bash
# Replace <pod-name> with one of your actual pod names
kubectl delete pod <pod-name>
```

Now check the Pods again to see how the ReplicaSet automatically creates a replacement:

```bash
kubectl get pods
```

You should still see 3 Pods, but one of them will be newer than the others.

## Step 6: Scale the ReplicaSet

Scale up the ReplicaSet to 5 replicas:

```bash
kubectl scale replicaset podinfo-rs --replicas=5
```

Verify that 2 new Pods were created:

```bash
kubectl get pods
```

Now scale down to 2 replicas:

```bash
kubectl scale replicaset podinfo-rs --replicas=2
```

Verify that 3 Pods were terminated:

```bash
kubectl get pods
```

## Step 7: Update the ReplicaSet

Try updating the image version in the ReplicaSet:

```bash
kubectl edit replicaset podinfo-rs
```

Change the image version from `stefanprodan/podinfo:6.7.1` to `stefanprodan/podinfo:6.3.6`, save and exit.

Check what happens to the existing Pods:

```bash
kubectl get pods -o custom-columns="POD:metadata.name,IMAGE:spec.containers[*].image"
```

**Important observation**: Existing Pods do not get updated when you change the ReplicaSet template! Only new Pods will use the updated template. This is a key limitation of ReplicaSets and why we typically use Deployments instead (as you'll learn in the next exercise).

To see the new version applied, delete all existing Pods:

```bash
kubectl delete pods --selector=app=podinfo
```

The ReplicaSet will create new Pods with the updated image version.

## Step 7.1: Run the `check.sh` script

Run the `check.sh` script to verify the pod is running correctly:

```bash
./check.sh
```

## Step 8: Delete the ReplicaSet

Clean up by deleting the ReplicaSet:

```bash
kubectl delete replicaset podinfo-rs
```

This will also delete all Pods managed by the ReplicaSet.

Alternatively, you can delete using the manifest file:

```bash
kubectl delete -f manifests/replicaset.yaml
```

## Challenges and Additional Exercises

1. **Selector Experiments**: Create Pods with the same labels as your ReplicaSet selector before creating the ReplicaSet. What happens?

2. **Label Updates**: What happens if you change the labels of a Pod that's part of a ReplicaSet?

3. **Disruption Scenarios**: Create a ReplicaSet with a large number of replicas, then simulate different types of failures:
   - Delete multiple Pods at once
   - Add a new node to your cluster (in a multi-node setup)
   - Force a Pod to fail (e.g., by modifying its container command to exit)

4. **Resource Competition**: What happens if you create multiple ReplicaSets competing for the same Pods via selector?

## Troubleshooting Guide

### Common ReplicaSet Issues

1. **ReplicaSet exists but no Pods are created**
   - Pod template may have errors
   - Label selector doesn't match template labels
   - Resource constraints preventing scheduling

   Resolution: Check events with `kubectl describe replicaset <replicaset-name>`

2. **ReplicaSet creates Pods but they keep failing**
   - Container image issues
   - Application crashes
   - Resource constraints

   Resolution: Check Pod logs and events

3. **ReplicaSet shows incorrect number of Pods**
   - Pods might match selector but were created independently
   - Selector conflicts with other controllers

   Resolution: Check selector and Pod labels with `kubectl get pods --show-labels`

## Next Steps

When you're ready, proceed to [Exercise 4: Deployments and Updates](../exercise-4-deployment/) to learn how Deployments manage ReplicaSets and enable controlled updates and rollbacks.
