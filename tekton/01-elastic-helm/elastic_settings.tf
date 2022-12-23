locals {
  elasticSettings = {
    globalSettings = {
      namespace   = "elastic",
      imageTag    = "7.17.8",
      clusterName = "elasticsearch",
      remotecerts = ["remote.ca.crt", "remote2.ca.crt"],
      plugins     = ["repository-s3"]
      addons = {
        notifications = {
          slack = {
            vault_path = "secret/test/elastic_notification"
          },
          email = {
            vault_path = "secret/test/elastic_notification"
          }
        },
        authorizations = {
          ga = {
            vault_path      = "secret/saml_google_sandbox"
            saml_realm_name = "geminiadvisory"
            secret_name     = "saml-geminiadvisory"
            type            = "saml"
            domain          = "k.t.regemini.io"
          }
        }
      },
      license = {
        vault_path = "secret/elasticsearch-admin/license"
        name       = "recorded-future-ab-non_production-c5c46fd1-a8b4-41d7-8e47-4cde5a71013a-v5.json"
      }
    },
    nodePools = {
      master = {
        replicas      = 1,
        workloadsType = "data",
        roles         = { master = "true" },
        resources     = { cpuReq = "250m", memReq = "512Mi", cpuLimit = "1", memLimit = "1Gi" },
        esJavaOpts    = ""
      },
      data = {
        replicas      = 2,
        workloadsType = "data",
        roles         = { data = "true" },
        resources     = { cpuReq = "250m", memReq = "512Mi", cpuLimit = "1", memLimit = "1Gi" },
        esJavaOpts    = ""
      },
      coor = {
        replicas      = 1,
        workloadsType = "data",
        roles         = {},
        resources     = { cpuReq = "250m", memReq = "512Mi", cpuLimit = "1", memLimit = "1Gi" },
        esJavaOpts    = ""
      }
    }
  }
}
