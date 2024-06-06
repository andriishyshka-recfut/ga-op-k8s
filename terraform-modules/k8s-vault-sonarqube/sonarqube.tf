# Minio creds will be used later for DB backups

# data "vault_generic_secret" "minio_credentials" {
#   path = "secret/minio/users"
# }


# locals {
#   accessKey               = jsondecode(data.vault_generic_secret.minio_credentials.data["sonarqube"]).accessKey
#   secretKey               = jsondecode(data.vault_generic_secret.minio_credentials.data["sonarqube"]).secretKey
# }


# resource "kubernetes_secret" "minio_credentials" {
#   metadata {
#     name      = "minio-credentials"
#     namespace = local.namespace
#   }

#   data = {
#     "accesskey" = local.accessKey
#     "secretkey" = local.secretKey
#   }
# }


resource "helm_release" "sonarqube" {
  name              = "sonarqube"
  repository        = "https://SonarSource.github.io/helm-chart-sonarqube"
  chart             = "sonarqube"
  version           = local.chart_version
  wait              = true
  atomic            = true
  namespace         = local.namespace
  set{
    name = "postgresql.persistence.size"
    value = local.diskSize
  }
  set{
    name = "image.tag"
    value = local.image_tag
  }
  # depends_on = [kubernetes_secret.minio_credentials]
}


resource "kubernetes_persistent_volume" "sonarqube_postgres_pv" {
  count = local.pv_disk_count
  metadata {
    name = "sonarqube-postgres-${count.index}-pv"
    labels = {
      target = "sonarqube-postgres"
    }
  }
  spec {
    capacity = {
      storage = local.diskSize
    }
    access_modes = ["ReadWriteOnce"]
    claim_ref {
      namespace = local.namespace
      name = "data-sonarqube-postgresql-${count.index}"
    }
    persistent_volume_source{
      csi {
        driver = "pd.csi.storage.gke.io"
        volume_handle = "projects/${var.Settings.gcpProject}/regions/${var.Settings.clusters[var.Cluster].region}/disks/sonarqube-postgres-${count.index}"
      }
    }
  node_affinity {
      required {
        node_selector_term {
          match_expressions {
            key = "topology.gke.io/zone"
            operator = "In"
            values = [ "us-east4-a", "us-east4-b"]            
          }
        }
      }
    }
  }
}

