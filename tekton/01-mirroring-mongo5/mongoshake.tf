data "vault_generic_secret" "mongo_creds" {
  path = var.Settings.clusters[var.Cluster].mongo.magescanner.vaultPath
}


locals {
  mongoshakeCommand = <<EOT
  set -e;
  apt-get update -q && apt-get install wget python3 python3-pymongo -yq ;
  wget https://github.com/alibaba/MongoShake/releases/download/release-v2.8.1-20220922/mongo-shake-v2.8.1.tgz -O mongoshake.tgz ;
  tar zxvf mongoshake.tgz ;
  cd mongo-shake-v2.8.1;
  ./collector.linux -conf=/etc/mongoshake/config -verbose 1

EOT
}

resource "kubernetes_secret" "mongoshake_config" {
  metadata {
    name      = "mongoshake-config"
    namespace = "mongo5"
  }
  data = {
    config = templatefile("${path.root}/mongoshake-conf.tftpl", {
      USER              = data.vault_generic_secret.mongo_creds.data.MONGODB_BACKUP_USER
      PASSWORD          = data.vault_generic_secret.mongo_creds.data.MONGODB_BACKUP_PASSWORD
      COLOR             = var.Color
    })
  }
}




resource "kubernetes_deployment" "mongoshake" {
  metadata {
    name      = "mongoshake"
    namespace = "mongo5"
  }
  spec {
    replicas = 1

    selector {
      match_labels = {
        app = "mongoshake"
      }
    }
    template {
      metadata {
        labels = {
          app = "mongoshake"
        }
        annotations = {
          "sidecar.istio.io/inject" = "false"
        }
      }
      spec {
        volume {
          name = "config"
          secret {
            secret_name = "mongoshake-config"
          }
        }
        container {
          name    = "mongoshake"
          image   = "mongo"
          command = ["bash", "-c", local.mongoshakeCommand]
          volume_mount {
            name       = "config"
            mount_path = "/etc/mongoshake"
          }
        }
      }
    }
  }
depends_on=[kubernetes_secret.mongoshake_config]
}
