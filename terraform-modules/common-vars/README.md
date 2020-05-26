## Description

This module contain configuration for all parts of infrastructure.

Currently in outputs defined values for :
* terraform-base - terraform configs for provisioning VPC/Bastion/etc.
* gke-setup module - module to spin up GKE cluster accessible over bastion


Configuration attributes defined as output values and may be accessible in standard way and not require serialization/deserialization within terraform. Here are example of including this module and accessing output value:
```

module "common-vars" {
  source = "../terraform-modules/common-vars"
}
***
resource "google_compute_instance" "bastion" {
  name = module.common-vars.bastion_hostname

***
```

To call module arguments from other tools it may be required to serialize data in json or yaml when passing complex structure :
```
provisioner "local-exec" {
    command = "cd ../ansible && ansible-playbook bastion-provision.yml --user sa_${data.google_service_account.me.unique_id} -e 'ansible_python_interpreter=/usr/bin/python3.7' "
    environment = {
    CLUSTER_SETTINGS = jsonencode(module.common-vars.cluster_settings)
    BASTION_DNS = module.common-vars.bastion_dns
    }
```
and from ansible side:
```
cluster_name: "{{ lookup('env','CLUSTER') }}"
cluster_settings: "{{ lookup('env','CLUSTER_SETTINGS') | from_json }}"

```
## Configuration reference

### terraform-base
```
# Bastion section
output "vpc_name" { value = "vpc" } // name of new vpc to create with terraform-base
output "bastion_hostname"{ value = "bastion" } // hostname for bastion VM. VM labeled with this value and ansble with gcp inventory can access it.
output "bastion_dns"{ value = "bastion.biriukov.tech" } // DNS name of bastion. Used to configure load Balancer and subspace. Certificate requested from Let's Encrypt during provisining with ansible
output "bastion_zone" { value = "us-east4-b" } // Zone where to spin up bastion VM
output "bastion_subnet_range" { value = "172.18.0.0/24" } // Specific subnet range for DMZ resources (like bastion)

```

### Cluster provisioning
```
// Cluster settings are grouped by cluster name
    "infra" = {
      // used to create namespace/service/and other resources withing provisioned cluster to verify deployment status and availibility
      "test_workload_name" = "test"
      // Region where to provision cluster
      "region" = "us-east4"
      // Base domain name. May be same for multiple clusters
      "domain" = "digaweb.local"
      // Subdomain that refer to cluster. Private zone will be created with Cloud DNS. subdomain + domain should be unique
      "subdomain" = "infra"
      // Subnet range for cluster nodes.Should not overlap with pods or services.
      "nodes_subnet_range" = "10.100.1.0/24"
      // Subnet range for pods. Should be unique and overlap any other cluster/infrastructure resource.
      "pods_subnet_range" = "10.100.8.0/21"
      // Services range should be unique and not overlap.
      "services_subnet_range" = "10.100.16.0/21"
      // Range for GKE master. Should not overlap any other range for whole infrastructure
      "master_ipv4_cidr_block" = "172.26.0.0/28"
      // Istio version to install during provisioning
      // this variable may be changed only before install. Istio has custom upgrade process
      // https://istio.io/docs/setup/upgrade/
      "istio_version" = "1.6.0"
      // Cert manager version to install during provisioning
      "cert_manager_version" = "v0.15.0"
    }

```
For each new cluster configuration reference MUST be present in cluster_settings map. Then gke-setup module may be called like:
```
module "gke-setup" {
  source = "../terraform-modules/gke-setup"

  settings = module.common-vars
  cluster = "infra"
}
```
