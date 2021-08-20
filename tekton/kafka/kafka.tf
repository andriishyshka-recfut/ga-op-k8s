
module "kafka" {
  source                       = "../../terraform-modules/k8s-vault-kafka"
  GkeClusterConnectionSettings = local.gkeClusterConnectionSettings
  }

provider "kubectl" {
    # alias = "kube"
    cluster_ca_certificate = data.vault_generic_secret.k8s_auth.data.CLUSTER_CA_CERTIFICATE
    host                   = data.vault_generic_secret.k8s_auth.data.HOST
    token                  = data.vault_generic_secret.k8s_auth.data.k8s_sa_token
    load_config_file       = false
  }
