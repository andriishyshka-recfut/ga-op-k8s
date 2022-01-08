data "vault_generic_secret" "mongo_creds" {
 path = var.Settings.clusters[var.Cluster].mongo.magescanner.vaultPath
}

locals {
  mongoshakeCommand = <<EOT
  set -e;
  apt-get update -q && apt-get install wget -yq ;
  wget https://github.com/alibaba/MongoShake/releases/download/release-v2.6.5-20210723-1/mongo-shake-v2.6.5.tar.gz -O mongoshake.tar.gz ;
  tar zxvf mongoshake.tar.gz ;
  cd mongo-shake-v2.6.5;
  ./collector.linux -conf=/etc/mongoshake/config -verbose 2

EOT
}

resource "kubernetes_secret" "mongoshake_config" {
  metadata {
    name = "mongoshake-config"
    namespace = "mongo"
  }
  data = {
    config = templatefile("${path.root}/mongoshake-conf.tftpl", {
      USER = data.vault_generic_secret.mongo_creds.data.MONGODB_BACKUP_USER
      PASSWORD = data.vault_generic_secret.mongo_creds.data.MONGODB_BACKUP_PASSWORD
      COLOR = var.Color
      SOURCE_CLUSTER_IP = data.external.get_remote_node.result.ip
      })
  }
}



resource "null_resource" "mongo_nodeport" {

  provisioner "local-exec" {
    interpreter = ["/bin/bash", "-c"]
    command     = <<COMMAND
    set -x
    kubectl apply --server ${data.vault_generic_secret.k8s_auth_inactive.data.HOST}  \
     --token ${data.vault_generic_secret.k8s_auth_inactive.data.k8s_sa_token}  \
     --insecure-skip-tls-verify=true  \
     -f ${path.root}/mongo-nodeport.yaml

COMMAND
  }
}


resource "kubernetes_deployment" "mongoshake" {
  metadata {
    name = "mongoshake"
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
            ip = host_aliases.value.ip
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
