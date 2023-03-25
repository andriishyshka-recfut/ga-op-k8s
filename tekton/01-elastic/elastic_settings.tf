locals {
  ElasticSettings = {
    globalSettings = {
      namespace   = "elastic",
      imageTag    = "7.17.9",
      clusterName = "elasticsearch",
      remotecerts = [],
      plugins     = ["repository-s3"]
      addons = {
        notifications = {
          slack = {
            vault_path = "secret/red/elastic-notification-accounts"
          },
          email = {
            vault_path = "secret/red/elastic-notification-accounts"
          }
        },
        authorizations = {
          ga = {
            vault_path      = "secret/red/saml/geminiadvisory"
            saml_realm_name = "geminiadvisory"
            secret_name     = "saml-geminiadvisory"
            type            = "saml"
            domain          = "k.regemini.com"
          }
        }
      },
      license = {
        vault_path = "secret/red/elasticsearch-admin/license"
        name       = "recorded-future-ab-production-83be3fc4-05e3-4804-ae89-2182fa5367d4-v5.json"
      }
    },
    nodePools = {
      master = {
        replicas      = 3,
        workloadsType = "mstr",
        roles         = { master = "true" },
        resources     = { cpuReq = "7", cpuLimit = "7", memReq = "24Gi", memLimit = "24Gi" },
        storage       = "30Gi",
        esJavaOpts    = "-Xms12g -Xmx12g"
      },
      data = {
        replicas      = 15,
        workloadsType = "data",
        roles         = { data = "true" },
        resources     = { cpuReq = "15", cpuLimit = "15", memReq = "52Gi", memLimit = "52Gi" },
        storage       = "750Gi",
        esJavaOpts    = "-Xms26g -Xmx26g"
      },
      coor = {
        replicas      = 3,
        workloadsType = "coor",
        roles         = {},
        resources     = { cpuReq = "7", cpuLimit = "7", memReq = "24Gi", memLimit = "24Gi" },
        storage       = "30Gi",
        esJavaOpts    = "-Xms12g -Xmx12g"
      }
    }
  }
}
