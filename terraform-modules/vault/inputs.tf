
data "google_project" "vault" {
}

variable "region" {
  type        = string
  default     = "us-east4"
  description = "Region in which to create the cluster and run Atlantis."
}

variable "gke_cluster_endpoint" { }

variable "gke_bearer_token" { }

variable "cluster_ca_certificate" { }

variable "settings" {}

variable "cluster" { }
variable "vault-version" {}
