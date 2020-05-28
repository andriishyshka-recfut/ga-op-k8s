
# Step by step guide to create new cluster.


### Here will be steps to provision new cluster with terraform

1. First make sure all stuff from terraform-base/ is done.
2. Connect to Wireguard VPN
3. Update cluster_settings variable with new cluster configuration in `terraform-modules/common-vars/outputs`
4. Create new directory where all cluster related configs will be placed
5. Create main.tf with next content:
```
terraform {
  backend "gcs" {
    bucket  = "[[ Bucket name with tf-states ]]"
    prefix  = "terraform-[[ cluster name]]/state" // path should be unique to all other clusters
  }
}



module "common-vars" {
  source = "../terraform-modules/common-vars" // should be a valid path to common-vars module directory
}

module "gke-setup" {
  source = "../terraform-modules/gke-setup"

  settings = module.common-vars
  cluster = "[[ cluster name]]" // Name of cluster which configuration were created in step 2.
}

```

6. Set env variables with path SA key json and run terraform
```
source ../.env

tf init
tf apply
```
