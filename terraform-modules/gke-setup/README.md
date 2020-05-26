This module spin up GKE cluster in private mode and create all required resources to be accessible from bastion:
* DNS
* Firewall Rules
* Master Authorized network

It's configuration is based on `common-vars` module. Please check configuration reference there.


Example usage:
```
module "gke-setup" {
  source = "../terraform-modules/gke-setup"

  settings = module.common-vars
  cluster = "infra"
}


```

where :
 source - valid path to module
 settings - reference on common-vars configuration
 cluster - name of cluster in common-vars settings 
