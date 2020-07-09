# Bastion section
output "vpc_name" { value = "vpc" }                       // name of new vpc to create with terraform-base
output "bastion_hostname" { value = "bastion" }           // hostname for bastion VM. VM labeled with this value and ansble with gcp inventory can access it.
output "bastion_dns" { value = "b.digaweb.com" }          // DNS name of bastion. Used to configure load Balancer and subspace. Certificate requested from Let's Encrypt during provisining with ansible
output "bastion_zone" { value = "us-east4-b" }            // Zone where to spin up bastion VM
output "bastion_subnet_range" { value = "172.18.0.0/24" } // Specific subnet range for DMZ resources (like bastion)


# GKE section
variable "cluster_settings" {
  default = {
    // Cluster settings are grouped by cluster name
    "infra" = {
      // used to create namespace/service/and other resources withing provisioned cluster to verify deployment status and availibility
      "test_workload_name" = "d-note"
      // Region where to provision cluster
      "region" = "us-east4"
      // Base domain name. May be same for multiple clusters
      "domain" = "digaweb.com"
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
      // https://www.terraform.io/docs/providers/google/r/container_cluster.html#default_max_pods_per_node
      "pods_per_node" = 33
      // vault section
      "vault" = {
        // vault version
        "version" = "1.4.2"
        // Fairly Qualified domain name used by vault. Will be used to expose service outside of cluster
        "fqdn" = "vault.infra.digaweb.com"
        // Expose vault with istio Gateway and cert-manager cert
        "istio_expose" = true
      }
      // Vault integration with cluster services section
      "vault_integration" = {
        // create serrvice account for vault and configure vault k8s auth under auth/k8s-{{ cluster_name }} path
        "enabled" = true
        // Cert-manager vault connection. Used for cert-manager's default ClusterIssuer
        // Supported values: local, other
        "connection" = "local"
        // VAULT_ADDR used by services within cluster. Usefull when vault installed in separate cluster
        "vault_addr" = "https://vault.infra.digaweb.com"
      }
      // cert-manager section
      "cert_manager" = {
        // Cert manager version to install during provisioning
        "version" = "v0.15.0"
      }
      // Istio section
      "istio" = {
        // Istio version to install during provisioning
        // this variable may be changed only before install. Istio has custom upgrade process
        // https://istio.io/docs/setup/upgrade/
        "version" = "1.6.4"
        // Whether to use certificates root CA from vault
        "use_vault_ca" = false

      }
    }
  }

}
output "cluster_settings" { value = "${var.cluster_settings}" }
