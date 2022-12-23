locals {
  KibanaSettings = {
    ga = {
      replicas      = 3,
      publicBaseUrl = "https://k.t.regemini.io"
      namespace     = "elastic"
      authorizations = {
        geminiadvisory = {
          type  = "saml",
          realm = "geminiadvisory"
        }
      }
    }
  }
}
