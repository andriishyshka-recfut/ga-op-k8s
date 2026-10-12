provider "vault" {
  address = var.VaultAddress
}

provider "zpa" {
  zpa_client_id     = local.zpa_client_id
  zpa_client_secret = local.zpa_client_secret
  zpa_customer_id   = local.zpa_customer_id
  zpa_cloud         = "PRODUCTION"
  use_legacy_client = true
}

terraform {
  backend "gcs" {
    bucket = "terraform-state-orbital-wording-233917"
    prefix = "terraform-zscaler-api/state"
  }

  required_providers {
    vault = {
      source = "hashicorp/vault"
    }
    zpa = {
      source  = "zscaler/zpa"
      version = "~> 4.4"
    }
  }
}
