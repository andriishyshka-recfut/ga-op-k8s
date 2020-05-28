 Thist folder contains config for provisionning GKE cluster with terraform ans it's dependencies




# Connect to Wireguard VPN
 Only then cluster provisioning may complete. In other way k8s API server won't be accessible


### RUN

1. Define required variables and aliases
```
source ../.env

```

2. Run terraform
```
tf init
tf plan
tf apply

```
