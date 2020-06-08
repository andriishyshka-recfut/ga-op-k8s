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
