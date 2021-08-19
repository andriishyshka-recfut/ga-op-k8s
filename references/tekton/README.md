

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


Create vault role


Create configmap
```
 k create configmap cluster-settings --from-literal=cluster=sandbox --from-literal=color=green --from-literal=configPath=config.tfvars.json
```

Create tekton task
```
 k apply -f /home/stepan/git/gemini/k8s/references/tekton/task.yaml
```


Create tuskrun
```
k apply -f /home/stepan/git/gemini/k8s/references/tekton/taskrun.yaml
```

Check results on tekton dashboard
http://tekton-dashboard:9097/
