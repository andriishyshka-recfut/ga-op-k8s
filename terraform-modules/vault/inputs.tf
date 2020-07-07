
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
variable "oidc_discovery_url" { default = "SAMPLE"}
variable  "oidc_client_id" { default = "SAMPLE"}
variable  "oidc_client_secret" { default = "SAMPLE"}

variable "bucket_name" {}
variable "autounseal_kms_crypto_key_id" {}
variable "autounseal_kms_crypto_key_name" { }
variable "autounseal_kms_key_ring_name" { }
