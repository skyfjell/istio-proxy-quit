# istio-proxy-quit

Container for quitting istio-proxy on Jobs. Runs as a container on a JobSpec with istio sidecars present.
This will, on an interval, check for all containers except itself and the istio-proxy to exit gracefully (exit code 0).

Mixing this container with [kyverno](https://kyverno.io) and [skyfjell/charts/kyverno-policies](https://github.com/skyfjell/charts/tree/main/charts/kyverno-policies) allows for automatic enabling on all jobs.

## Config

### RBAC

RBAC is required to get this running correctly. The service account attached to the Pod needs to be given readonly permissions on that pod.

```yaml
apiVersion: rbac.authorization.k8s.io/v1
kind: Role
metadata:
  name: pod-read
  namespace: job-test
rules:
  - apiGroups: [""]
    resources: ["pods"]
    verbs: ["get", "watch", "list"]
---
apiVersion: rbac.authorization.k8s.io/v1
kind: RoleBinding
metadata:
  name: pod-read
  namespace: job-test
subjects:
  - kind: ServiceAccount
    name: "default"
    namespace: job-test
roleRef:
  kind: Role
  name: pod-read
  apiGroup: rbac.authorization.k8s.io
```

### Environment Variables

- `ISTIO_PROXY_NAME`: Name of the istio proxy container, defaults to `istio-proxy`
- `ISTIO_ENDPOINT`: Name of the istio proxy pod endpoint, defaults to `127.0.0.1:15020`
- `K8S_SELF_NAME`: Name of the container this image runs as, defaults to `istio-proxy-quit`
- `K8S_NAMESPACE`: Namespace of this pod, pass in via [downward api](https://kubernetes.io/docs/concepts/workloads/pods/downward-api/)
- `SLEEP_INTERVAL`: Interval of the polling, passed to bash `sleep` command, defaults to `5s`.
- `API_SERVER`: Url of kubernetes api server, defaults to `https://kubernetes.default.svc`.
- `SERVICE_ACCOUNT`: Service account mount path, defaults to `/var/run/secrets/kubernetes.io/serviceaccount`

### Usage on a Job

```yaml
---
apiVersion: v1
kind: Namespace
metadata:
  name: job-test
  labels:
    istio-injection: enabled
---
apiVersion: batch/v1
kind: Job
metadata:
  name: pi
  namespace: job-test
spec:
  template:
    spec:
      containers:
        - name: istio-proxy-quit
          image: "ghcr.io/skyfjell/istio-proxy-quit:latest"
          imagePullPolicy: Never
          env:
            - name: K8S_NAMESPACE
              valueFrom:
                fieldRef:
                  fieldPath: metadata.namespace
        - name: pi
          image: perl:5.34.0
          command: ["perl", "-Mbignum=bpi", "-wle", "print bpi(2000)"]
      restartPolicy: Never
  backoffLimit: 1
```
