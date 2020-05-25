output "vpc_name" {
  value = "vpc"
}

output "bastion_hostname"{
  value = "bastion"
}

output "bastion_dns"{
  value = "bastion.biriukov.tech"
}

output "bastion_zone" {
  value = "us-east4-b"
}

output "bastion_subnet_range" {
  value = "172.18.0.0/24"
}


variable "cluster_settings" {
  default = {
    "test_workload_name" = "test",
    "infra" = {
      "domain" = "digaweb.local"
      "subdomain" = "infra"
      "nodes_subnet_range" = "10.100.1.0/24"
      "pods_subnet_range" = "10.100.8.0/21"
      "services_subnet_range" = "10.100.16.0/21"
      "master_ipv4_cidr_block" = "172.26.0.0/28"
      // this variable may be changed only before install. Istio has custom upgrade process
      // https://istio.io/docs/setup/upgrade/
      "istio_version" = "1.6.0"
      "cert_manager_version" = "v0.15.0"
    }
  }

}

output "cluster_settings" {
  value = "${var.cluster_settings}"
}
