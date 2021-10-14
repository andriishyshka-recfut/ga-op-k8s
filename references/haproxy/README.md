


1. Create secret:
```
kubectl create secret generic ssl --from-file=ca.crt --from-file=haproxy.pem --from-file=crl.pem
```

2. Run haproxy :

```
kubectl apply -k .
```

3. Verify
```
curl -vvvk --cert client.crt --key client.key --request GET "https://elastic:$ES_PASSWORD@haproxy:9200/_cat/indices?v"
```


4. Create jks:
```
openssl pkcs12 -export -in client.crt -inkey client.key -name client -out client.p12 -passout pass:

```
