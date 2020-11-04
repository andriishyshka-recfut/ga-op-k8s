1.
```
kubectl apply -f namespace.yaml
```

2.

```
kubectl create secret docker-registry harbor --docker-server=harbor.infra.digaweb.com \
 --docker-username=$(vault kv get -field=user  secret/goharbor/docker_login) \
 --docker-password=$(vault kv get -field=password  secret/goharbor/docker_login) \
 --docker-email=k8s@example.com

```
