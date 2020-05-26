# Bastion section
output "vpc_name" { value = "vpc" } // name of new vpc to create with terraform-base
output "bastion_hostname"{ value = "bastion" } // hostname for bastion VM. VM labeled with this value and ansble with gcp inventory can access it.
output "bastion_dns"{ value = "b.digaweb.com" } // DNS name of bastion. Used to configure load Balancer and subspace. Certificate requested from Let's Encrypt during provisining with ansible
output "bastion_zone" { value = "us-east4-b" } // Zone where to spin up bastion VM
output "bastion_subnet_range" { value = "172.18.0.0/24" } // Specific subnet range for DMZ resources (like bastion)


# GKE section
variable "cluster_settings" {
  default = {
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
    "dev" = {
      "test_workload_name" = "test"
      "region" = "us-east4"
      "region" = "us-east4"
      "domain" = "digaweb.local"
      "subdomain" = "dev"
      "nodes_subnet_range" = "10.101.1.0/24"
      "pods_subnet_range" = "10.101.8.0/21"
      "services_subnet_range" = "10.101.16.0/21"
      "master_ipv4_cidr_block" = "172.26.0.16/28"
      // this variable may be changed only before install. Istio has custom upgrade process
      // https://istio.io/docs/setup/upgrade/
      "istio_version" = "1.6.0"
      "cert_manager_version" = "v0.15.0"
    }
  }

}
output "cluster_settings" { value = "${var.cluster_settings}" }
