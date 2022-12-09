locals {
  elasticSettings = {
    globalSettings = {
      namespace   = "elastic",
      imageTag    = "7.17.8",
      clusterName = "elasticsearch",
      remotecerts = ["remote.ca.crt", "remote2.ca.crt"],
      plugins     = ["repository-s3", "repository-gcs"]
      addons = {
        notifications = {},
        authorizations = {
          ga = {
            vault_path      = "secret/elasticsearch-admin/saml_geminiadvisory_sandbox"
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
        resources     = { cpuReq = "3", memReq = "4Gi", cpuLimit = "4", memLimit = "5Gi" },
        storage       = "100Gi",
        esJavaOpts    = "-Xms4g -Xmx4g"
      },
      data = {
        replicas      = 2,
        workloadsType = "data",
        roles         = { data = "true" },
        resources     = { cpuReq = "1", memReq = "4Gi", cpuLimit = "4", memLimit = "5Gi" },
        storage       = "100Gi",
        esJavaOpts    = "-Xms4g -Xmx4g"
      },
      coor = {
        replicas      = 1,
        workloadsType = "data",
        roles         = {},
        resources     = { cpuReq = "1", memReq = "4Gi", cpuLimit = "4", memLimit = "5Gi" },
        storage       = "100Gi",
        esJavaOpts    = "-Xms4g -Xmx4g"
      }
    }
  }
}
