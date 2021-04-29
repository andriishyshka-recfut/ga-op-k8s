module "prometheus" {
  source   = "../../../terraform-modules/k8s-vault-prometheus"
  OidcSecretVaultPath = "secret/oidc_google_test"
}
