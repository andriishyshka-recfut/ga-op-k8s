* Run ansible playbook second time:
```
### Find playbook name in terraform output and remove it from state
terraform state rm module.gke-setup2.null_resource.ansible_bastion_playbook

terraform apply
```
