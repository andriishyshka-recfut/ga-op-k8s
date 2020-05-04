output "vpc_name" {
  value = "vpc"
}

output "bastion_hostname"{
  value = "bastion"
}

output "bastion_zone" {
  value = "europe-west3-b"
}

output "bastion_subnet_range" {
  value = "10.100.0.0/24"
}

output "infra_nodes_subnet_range" {
  value = "10.100.1.0/24"
}

output "infra_pods_subnet_range" {
  value = "10.100.8.0/21"
}

output "infra_services_subnet_range" {
  value = "10.100.16.0/21"
}
