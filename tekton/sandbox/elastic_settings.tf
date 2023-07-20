locals {
  ElasticSettings = {
    globalSettings = {
      namespace            = "elastic",
      imageTag             = var.Settings.clusters[var.Cluster][var.Color].elasticsearch.cluster.elastic
      clusterName          = "elasticsearch",
      remotecerts          = ["remote.ca.crt", "remote2.ca.crt"],
      remoteCertsVaultPath = "secret/elasticsearch-admin/remote-certs",
      plugins              = ["repository-s3", "repository-gcs"]
      gcsVaultPath         = "secret/sa/prod-transfer"
      volumeExt            = false
      podAnnotations = {
        "co.elastic.logs/enabled" : "true",
        "co.elastic.logs/module" : "elasticsearch",
        "sidecar.istio.io/inject" : "false",
        "co.elastic.logs/exclude_lines" : "^.*\"event.type\":\"transport\""
      }
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
        name       = "recorded-future-ab-non_production-200efd96-e649-42ae-989d-859bcb15e9e3-v5.json"
      },
      clusterHealthCheckParams = "wait_for_status=green&timeout=1s"
    },
    nodePools = {
      master = {
        replicas      = 3,
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
        storage       = "150Gi",
        esJavaOpts    = "-Xms4g -Xmx4g"
      },
      coor = {
        replicas      = 2,
        workloadsType = "data",
        roles         = {},
        resources     = { cpuReq = "1", memReq = "4Gi", cpuLimit = "4", memLimit = "5Gi" },
        storage       = "100Gi",
        esJavaOpts    = "-Xms4g -Xmx4g"
      },
      ingest = {
        replicas      = 1,
        workloadsType = "data",
        roles         = { ingest = "true" },
        resources     = { cpuReq = "1", memReq = "4Gi", cpuLimit = "4", memLimit = "5Gi" },
        storage       = "100Gi",
        esJavaOpts    = "-Xms4g -Xmx4g"
      }
    }
  }
}
