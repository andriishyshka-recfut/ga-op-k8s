locals {
  KibanaSettings = {
    ga = {
      basic_auth    = true
      replicas      = 3,
      publicBaseUrl = "https://k.t.regemini.io"
      namespace     = "elastic"
      authorizations = {
        geminiadvisory = {
          type  = "saml",
          realm = "geminiadvisory"
        }
      }
      kibana_xpack_secrets = "secret/kibana"
    },
    test = {
      replicas      = 1,
      publicBaseUrl = "https://k2.t.regemini.io"
      namespace     = "elastic"
      authorizations = {
        okta = {
          type  = "okta",
          realm = "okta"
        }
      }
      kibana_xpack_secrets = "secret/mw/kibana/xpack_secrets/test"
    }
  }
}
