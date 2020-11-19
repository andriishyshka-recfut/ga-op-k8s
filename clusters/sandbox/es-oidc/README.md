
1.
```
kubectl create secret generic oidc --namespace monitoring  --from-literal=xpack.security.authc.realms.oidc.oidc1.rp.client_secret=value
```

2.
```
secureSettings:
- secretName: oidc


    tls:
      certificate: {}
      selfSignedCertificate:
        disabled: false

xpack.security.authc.token.enabled: true

        oidc:
          oidc1:
            order: 2
            rp.response_type: code
            rp.redirect_uri: https://kibana.infra.digaweb.com/api/security/oidc/callback
            op.issuer: https://accounts.google.com
            op.authorization_endpoint: https://accounts.google.com/o/oauth2/v2/auth
            op.token_endpoint: https://oauth2.googleapis.com/token
            op.jwkset_path: https://www.googleapis.com/oauth2/v3/certs
            claims.principal: "email"
            rp.requested_scopes:
              - email
              - openid
              - profile
            rp.client_id: 921970745198-3541scevmu5oogrlucmu0poh7kn9a7ms.apps.googleusercontent.com
```

3. kibana
```


xpack.security.authc.providers:
  oidc.oidc1:
    order: 0
    realm: "oidc1"


```

4. Role mapping
```
curl -X PUT "https://user:password@monitoring-es-http:9200/_security/role_mapping/oidc-example?pretty" -H 'Content-Type: application/json' -k -d'
{
  "roles": [ "superuser" ],
  "enabled": true,
  "rules": {
    "field": { "realm.name": "oidc1" }
  }
}
'

```
