locals {
  date_now = formatdate("YYYYMMDD", timestamp())
}

data "kubernetes_secret" "password" {
  metadata {
    name      = "elastic-credentials"
    namespace = "elastic"
  }
}

data "kubernetes_secret" "certs" {
  metadata {
    name      = "elastic-https-certs"
    namespace = "elastic"
  }
}


resource "null_resource" "elastic_restore" {
  triggers = {
    restore_check = md5(file("../../references/elastic-restore/restore.py"))
  }
  provisioner "local-exec" {
    command = <<COMMAND
    python3 "../../references/elastic-restore/restore.py"
COMMAND
    environment = {
      ELASTICSEARCH_USERNAME = "elastic"
      ELASTICSEARCH_PASSWORD = nonsensitive(data.kubernetes_secret.password.data.elastic)
      ELASTICSEARCH_URL      = "elasticsearch-coor.elastic.svc:9200"
      CA_CERT                = nonsensitive(data.kubernetes_secret.certs.data["ca.crt"])
      WAIT_FC                = "true"
      SNAPSHOTS              = "elastic7-dr-system-${local.date_now},elastic7-dr-other-${local.date_now}"
    }
  }
  depends_on = [module.es7-backup]
}

