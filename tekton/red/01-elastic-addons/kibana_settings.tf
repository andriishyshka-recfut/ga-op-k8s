locals {
  KibanaSettings = {
    ga = {
      basic_auth    = true,
      replicas      = 3,
      publicBaseUrl = "https://k.regemini.com"
      namespace     = "elastic"
      authorizations = {
        geminiadvisory = {
          type  = "saml",
          realm = "geminiadvisory"
        }
      }
      kibana_xpack_secrets_vault = "secret/red/kibana"
    }
  }
}
