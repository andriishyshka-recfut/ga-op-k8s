provider "google" {
  # version = "v3.19.0"
}
provider "vault" {
  address = "https://vault.infra.digaweb.com"
}

data "vault_generic_secret" "k8s_auth" {
  path = "secret/kubernetes-sandbox"
}


provider "helm" {
  # alias = "helm"
  kubernetes {
    load_config_file       = false
    host                   = data.vault_generic_secret.k8s_auth.data.HOST
    cluster_ca_certificate = data.vault_generic_secret.k8s_auth.data.CLUSTER_CA_CERTIFICATE
    token                  = data.vault_generic_secret.k8s_auth.data.k8s_sa_token
  }
}



data "google_project" "current" {}

#Create the storage bucket
resource "google_storage_bucket" "elastic-snapshots" {
  name          = "harbor-backet-${data.google_project.current.project_id}"
  project       = data.google_project.current.project_id
  force_destroy = true
  storage_class = "MULTI_REGIONAL"

  bucket_policy_only = true

  versioning {
    enabled = true
  }

  lifecycle_rule {
    action {
      type = "Delete"
    }
    condition {
      num_newer_versions = 1
    }
  }
}
