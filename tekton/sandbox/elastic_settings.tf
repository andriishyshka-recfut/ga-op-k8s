locals {
  ElasticSettings = {
    globalSettings = {
      namespace             = "elastic",
      imageTag              = var.Settings.clusters[var.Cluster].versions.elasticsearch.cluster.elastic
      clusterName           = "elasticsearch",
      remotecerts           = ["remote.ca.crt", "remote2.ca.crt"],
      remoteCertsVaultPath  = "secret/elasticsearch-admin/remote-certs",
      plugins               = ["repository-s3"]
      gcsVaultPath          = "secret/sa/prod-transfer"
      volumeExt             = false
      patchVaultEnabled     = true
      patchVaultPath        = "secret/elasticsearch-admin/elastic7-v2"
      patchVaultKey         = "CREDENTIALS"
      patchVaultInternalKey = "password"

      podAnnotations = {
        "co.elastic.logs/enabled" : "true",
        "co.elastic.logs/module" : "elasticsearch",
        "sidecar.istio.io/inject" : "false",
        "co.elastic.logs/exclude_lines" : "^.*\"event.type\":\"transport\""
      }
      transport = {
        verification_mode = "certificate"
        certs             = ["monthly"]
        active            = "monthly"
        duration          = "1080h"
      }
      addons = {
        notifications = {
          slack = {
            vault_path = "secret/misc/slack/app/X-Pack"
          }
        },
        authorizations = {
          okta = {
            vault_path      = "secret/misc/oidc/okta/elastic"
            oidc_realm_name = "okta"
            secret_name     = "oidc-okta"
            type            = "okta"
            domain          = "k.t.regemini.io"
          }
        }
      },
      license = {
        vault_path = "secret/misc/elasticsearch/license"
        name       = "recorded-future-ab-non_production-b3d2ba33-a0df-4cf6-9a5b-941d2bb9952c-v5.json"
      },
      clusterHealthCheckParams = "wait_for_status=green&timeout=1s"
    },
    nodePools = {
      master = {
        replicas      = 3,
        workloadsType = "data",
        roles         = { master = "true" },
        resources     = { cpuReq = "2", memReq = "4Gi", cpuLimit = "3", memLimit = "5Gi" },
        storage       = "100Gi",
        esJavaOpts    = "-Xms4g -Xmx4g"
      },
      data = {
        replicas      = 2,
        workloadsType = "data",
        roles         = { data = "true" },
        resources     = { cpuReq = "1", memReq = "4Gi", cpuLimit = "4", memLimit = "5Gi" },
        storage       = "170Gi",
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
