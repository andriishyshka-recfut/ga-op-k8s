
data "google_project" "vault" {
}

variable "region" {
  type        = string
  default     = "us-east4"
  description = "Region in which to create the cluster and run Atlantis."
}

// k8s connection settings
variable "gke_cluster_endpoint" {}
variable "gke_bearer_token" {}
variable "cluster_ca_certificate" {}

// Cluster variables and settings from common-vars module
variable "settings" {}
variable "cluster" {}


// OIDC setup settings. Should be passed as env variables during execution
variable "oidc_discovery_url" { default = "SAMPLE" }
variable "oidc_client_id" { default = "SAMPLE" }
variable "oidc_client_secret" { default = "SAMPLE" }


// Locks from  external modules
variable "istio_deployment_completion_lock" {}
