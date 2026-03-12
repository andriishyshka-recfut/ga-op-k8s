locals {
  Kibana8Settings = {
    okta = {
      basic_auth           = true,
      replicas             = 2,
      publicBaseUrl        = "https://k8.t.regemini.io"
      maxImportExportSize  = 105000
      namespace            = "elastic8"
      kibana_xpack_secrets = "secret/mw/kibana/xpack_secrets/test"
      authorizations       = {
        okta = {
          type        = "okta",
          realm       = "okta",
          description = "Log in with OKTA/RecordedFuture"
        }
      }
    }
  }
}
