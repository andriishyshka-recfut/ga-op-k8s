 Thist folder contains config for provisionning GKE cluster with terraform ans it's dependencies



### Before you begin
```
pip install kubernetes --user
pip install openshift --user

# Run new ssh-agent
eval(ssh-agent)
```


# Connect to Wireguard VPN
 Only then cluster provisioning may complete. In other way k8s API server won't be accessible


### RUN

1. Define required variables
```
export GOOGLE_CREDENTIALS=~/terraform_key.json
export GOOGLE_REGION=us-east4
export GOOGLE_PROJECT=silent-eye-276318


```

2. Run terraform
```
terraform init
terraform plan
terraform apply

# Stop ssh-agent
ssh-agent -k
```
