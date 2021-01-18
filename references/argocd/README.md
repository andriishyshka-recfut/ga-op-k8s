1.
```
# kubectl create namespace argocd
#kubectl apply -n argocd -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml

#helm repo add argo https://argoproj.github.io/argo-helm

#helm install argo argo/argo-cd -n argocd --set 'server.extraArgs[0]=--insecure'

tf apply

```
2.
```
kubectl apply -f ingress.yaml
kubectl apply -f kafka-operator.yaml
kubectl apply -f minio-ingress.yaml
```



Cleanup
```

#helm uninstall argo -n argocd
tf destroy


```
