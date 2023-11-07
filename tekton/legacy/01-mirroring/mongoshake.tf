data "vault_generic_secret" "mongo_creds" {
  path = var.Settings.clusters[var.Cluster].mongo.magescanner.vaultPath
}

provider "kubernetes" {
  alias                  = "kubernetes-inactive"
  host                   = data.vault_generic_secret.k8s_auth_inactive.data.HOST
  cluster_ca_certificate = data.vault_generic_secret.k8s_auth_inactive.data.CLUSTER_CA_CERTIFICATE
  token                  = data.vault_generic_secret.k8s_auth_inactive.data.k8s_sa_token
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
  count = local.prod_runs
  metadata {
    name      = "mongoshake-config"
    namespace = "mongo"
  }
  data = {
    config = templatefile("${path.root}/mongoshake-conf.tftpl", {
      USER              = data.vault_generic_secret.mongo_creds.data.MONGODB_BACKUP_USER
      PASSWORD          = data.vault_generic_secret.mongo_creds.data.MONGODB_BACKUP_PASSWORD
      COLOR             = var.Color
      SOURCE_CLUSTER_IP = data.external.get_remote_node.result.ip
    })
  }
}



resource "kubernetes_service" "mongo_nodeport" {
  count = local.prod_runs
  metadata {
    name      = "rs0-mongo-nodeport"
    namespace = "mongo"
  }
  provider = kubernetes.kubernetes-inactive
  spec {
    selector = {
      "app.kubernetes.io/instance"   = "${local.inactiveCluster}"
      "app.kubernetes.io/managed-by" = "percona-server-mongodb-operator"
      "app.kubernetes.io/name"       = "percona-server-mongodb"
      "app.kubernetes.io/part-of"    = "percona-server-mongodb"
      "app.kubernetes.io/replset"    = "rs0"
    }
    port {
      name        = "nodeportredis"
      port        = 27017
      target_port = 27017
      node_port   = 32170
      protocol    = "TCP"
    }
    type = "NodePort"
  }
}


resource "kubernetes_deployment" "mongoshake" {
  count = local.prod_runs
  metadata {
    name      = "mongoshake"
    namespace = "mongo"
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
        dynamic "host_aliases" {
          for_each = jsondecode(data.external.get_remote_node.result.mongo_dns)
          content {
            ip        = host_aliases.value.ip
            hostnames = [host_aliases.value.hostname]
          }
        }
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

}
