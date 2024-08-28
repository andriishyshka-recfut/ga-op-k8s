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
      kibana_xpack_secrets = "secret/red/kibana"
    },
    recordedfuture = {
      replicas      = 1,
      publicBaseUrl = "https://kk.regemini.com"
      namespace     = "elastic"
      authorizations = {
        okta = {
          type  = "okta",
          realm = "recordedfuture"
        }
      }
      kibana_xpack_secrets = "secret/mw/kibana/xpack_secrets/recordedfuture"
    }
  }
}
