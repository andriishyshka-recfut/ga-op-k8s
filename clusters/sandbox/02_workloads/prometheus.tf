module "prometheus" {
  source   = "../../../terraform-modules/k8s-prometheus"
  OidcSecretVaultPath = "secret/oidc_google_test"
}
