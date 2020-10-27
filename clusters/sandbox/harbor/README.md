
1. Init:
```
tf init

```

2. Create harbor

```

kubectl apply -f namespace.yaml
kubectl apply -f harbor-cert.yaml
kubectl apply -f ingress.yaml

tf apply


```

3. Next configure OIDC Access - https://goharbor.io/docs/1.10/administration/configure-authentication/oidc-auth/



4. Vault [gitlab jwt auth](https://docs.gitlab.com/ee/ci/examples/authenticating-with-hashicorp-vault/)
```
vault auth enable jwt
cat gitlab_jwt_auth_role.json| vault write auth/jwt/role/gitlab-dev -
cat gitlab_jwt_auth_config.json| vault write auth/jwt/config -
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

<!-- helm install harbor harbor/harbor --set expose.type=ClusterIP \
  --set expose.clusterIP.name=harbor \
  --set harborAdminPassword=admin \
  --set expose.tls.enabled=false \
  --set logLevel=warning \
  --set externalURL=https://harbor.infra.digaweb.com\
  --version=v1.5.0 \
  -n harbor -->
