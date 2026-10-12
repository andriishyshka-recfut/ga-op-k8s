locals {
  KibanaSettings = {
    ga = {
      basic_auth           = true,
      replicas             = 3,
      publicBaseUrl        = "https://k.regemini.com"
      maxImportExportSize  = 105000
      namespace            = "elastic"
      authorizations       = {}
      kibana_xpack_secrets = "secret/red/kibana"
    },
    recordedfuture = {
      replicas            = 3,
      publicBaseUrl       = "https://kk.regemini.com"
      maxImportExportSize = 105000
      namespace           = "elastic"
      authorizations = {
        okta = {
          type        = "okta",
          realm       = "recordedfuture"
          description = "Log in with OKTA/RecordedFuture"
        }
      }
      kibana_xpack_secrets = "secret/mw/kibana/xpack_secrets/recordedfuture"
    }
  }
  MonKibanaSettings = {
    monitoring = {
      replicas            = 2,
      publicBaseUrl       = "https://mon.regemini.io"
      maxImportExportSize = 105000
      namespace           = "monitoring"
      basic_auth           = true,
      authorizations = {
        okta = {
          type        = "okta",
          realm       = "recordedfuture"
          description = "Log in with OKTA/RecordedFuture"
        }
      }
      kibana_xpack_secrets = "secret/mw/kibana/xpack_secrets/monitoring"
    }
  }
}
