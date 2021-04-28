

1. Install kamel client from https://github.com/apache/camel-k/releases

2. Install camel-k:

```
kamel install -n kafka --registry harbor.t.regemini.io --registry-secret harbor
```

3. Create kafka topic:
```
k apply -f topics.yaml
```

4. Create `gmail-credentials` :
```
kubectl create secret generic gmail-credentials --from-literal=username=stepan.biriukov@geminiadvisory.io --from-literal=password=<secret>

```
