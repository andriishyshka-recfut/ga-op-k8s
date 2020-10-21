
1. Create bucket:
```
tf init
tf apply
```

2.

```

kubectl apply -f namespace.yaml
kubectl apply -f harbor-cert.yaml
kubectl apply -f ingress.yaml

helm install harbor harbor/harbor --set expose.type=ClusterIP \
  --set expose.clusterIP.name=harbor \
  --set harborAdminPassword=admin \
  --set expose.tls.enabled=false \
  --set logLevel=warning \
  --set externalURL=https://harbor.infra.digaweb.com\
  --version=v1.5.0 \
  -n harbor



```

<!-- helm install harbor harbor/harbor --set expose.type=ingress \
  --set expose.ingress.hosts.core=harbor.infra.digaweb.com \
  --set expose.ingress.annotations."kubernetes\.io\/ingress\.class"=istio \
  --set expose.tls.certSource=secret \
  --set expose.tls.secret.secretName=harbor-core-cert \
  --set harborAdminPassword=admin \
  --set logLevel=debug \
  --set externalURL=https://harbor.infra.digaweb.com \
  --version=v1.5.0 \
  -n harbor -->
