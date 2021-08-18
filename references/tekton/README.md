

Install :

```
kubectl apply --filename https://storage.googleapis.com/tekton-releases/pipeline/previous/v0.27.1/release.yaml

kubectl apply --filename https://storage.googleapis.com/tekton-releases/dashboard/latest/tekton-dashboard-release.yaml

```

Add image pull secret to

```
k apply -f ~/tmp/harbor
kubectl patch serviceaccount default -p '{"imagePullSecrets": [{"name": "harbor"}]}'

```

Create gitlab token :

```
kubectl create secret generic gitlab-token --from-literal=username=[[ USER ]] --from-literal=token=[[ TOKEN ]]
```
