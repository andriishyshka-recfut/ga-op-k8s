variable "Settings" {}
variable "Cluster" {}

locals {
  ingressSettings = var.Settings.clusters[var.Cluster].ingress
  certManager     = { for ingress, data in local.ingressSettings : ingress => data if lookup(data, "cert-manager", false) }
  virtualService  = merge([for ingress, data in local.ingressSettings : { for service in data.services : "${ingress}-${lookup(service, "name", service.service)}" => { "service" = "${lookup(service, "name", service.service)}", "ingress" = "${ingress}", "index" = index(data.services, service) } }]...)
}


