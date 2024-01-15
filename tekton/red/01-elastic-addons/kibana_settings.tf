locals {
  KibanaSettings = {
    ga = {
      replicas      = 3,
      publicBaseUrl = "https://k.regemini.com"
      namespace     = "elastic"
      authorizations = {
        geminiadvisory = {
          type  = "saml",
          realm = "geminiadvisory"
        }
      }
      kibana_xpack_secrets = "secret/red/kibana"
    }
  }
}
