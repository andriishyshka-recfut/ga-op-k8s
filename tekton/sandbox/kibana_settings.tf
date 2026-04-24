locals {
  KibanaSettings = {
    okta = {
      basic_auth           = true,
      replicas             = 2,
      publicBaseUrl        = "https://k.t.regemini.io"
      maxImportExportSize  = 105000
      namespace            = "elastic"
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