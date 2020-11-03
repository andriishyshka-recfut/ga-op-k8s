install
1.
```
helm repo add fluxcd https://charts.fluxcd.io
kubectl create namespace flux

kubectl create secret generic flux-git-auth --namespace flux --from-literal=GIT_AUTHUSER=<username> --from-literal=GIT_AUTHKEY=<token>


helm install  flux fluxcd/flux \
--set git.url='https://$(GIT_AUTHUSER):$(GIT_AUTHKEY)@gitlab.regemini.com/op/sandbox.git' \
--set env.secretName=flux-git-auth \
--set git.branch=kubernetes \
--set git.path=sandbox-ns/ \
--set 'allowedNamespaces[0]=sandbox' \
--set registry.automationInterval=1m \
--set git.pollInterval=1m \
--set git.ciSkip=true \
--namespace flux

```

<!-- --set git.readonly=true \ -->

cleanup

```
helm uninstall flux -n flux
```
