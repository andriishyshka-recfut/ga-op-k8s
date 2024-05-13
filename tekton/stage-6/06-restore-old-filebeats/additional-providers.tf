# data "vault_generic_secret" "k8s_auth_inactive" {
#   path = local.inactiveClusterVaultPath
# }
# provider "kubernetes" {
#   alias = "kubernetes-inactive"
#   host                   = data.vault_generic_secret.k8s_auth_inactive.data.HOST
#   cluster_ca_certificate = data.vault_generic_secret.k8s_auth_inactive.data.CLUSTER_CA_CERTIFICATE
#   token                  = data.vault_generic_secret.k8s_auth_inactive.data.k8s_sa_token
# }
