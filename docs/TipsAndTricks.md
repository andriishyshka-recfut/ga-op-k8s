* Run ansible playbook second time:
```
### Find playbook name in terraform output and remove it from state
terraform state rm module.gke-setup2.null_resource.ansible_bastion_playbook

terraform apply
```

* Start bastion as Service Account
```
gcloud iam service-accounts list --format=json --filter="email ~ terraform" | jq '.[0].email' -j
gcloud auth activate-service-account $(gcloud iam service-accounts list --format=json --filter="email ~ terraform" | jq '.[0].email' -j) --key-file $GOOGLE_CREDENTIALS
gcloud compute instances start bastion --zone us-east4-b

```

* TF state unlock after failure
```
# tf apply        

* * *

Lock Info:
  ID:        1590589709718259

* * *

# tf force-unlock 1590589709718259
Do you really want to force-unlock?
  Terraform will remove the lock on the remote state.
  This will allow local Terraform commands to modify this state, even though it
  may be still be in use. Only 'yes' will be accepted to confirm.

  Enter a value: yes

Terraform state has been successfully unlocked!

The state has been unlocked, and Terraform commands should now be able to
obtain a new lock on the remote state.

```

* Reinstall vault. Because vault use stateful sets update and patches may fail it. We have all statefull data outside cluster and it is pretty safe to delete helm release and install vault from scratch
```
helm uninstall  vault -n vault
tf apply

```

* Login to gke node
```
wg-quick up wg0

gcloud compute ssh  gke-infra-infra-node-pool-e9116048-m59c --zone us-east4-c  --internal-ip

```

* Scale Down the cluster safely
```

kubectl taint nodes gke-infra-infra-node-pool-e9116048-984m key1=value1:NoExecute
# k8s should remove all pods after this that not made by DaemonSets

# Forces PODs removing
kubectl drain gke-infra-infra-node-pool-e9116048-984m --ignore-daemonsets


# GKE Cluster Autoscheduler will remove node in hour or few

```

* Load Kibana dashboards
```
kubectl exec -it metricbeat-xp5jn -n kube-system -- metricbeat setup --dashboards -E setup.kibana.host=https://kibana-kb-http.elastic:5601 -E setup.kibana.ssl.verification_mode=none

```


# Get vault token without Jumphost balancer configured
```
kubectl port-forward service/vault 8200 -n vault &
export VAULT_ADDR='http://127.0.0.1:8200'
vault login -method=oidc role=111

```
