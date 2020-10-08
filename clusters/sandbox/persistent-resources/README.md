 Thist folder contains config for provisionning statefull resources for infra cluster (mostly storage buckets and Cloud KMS keys)




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
