locals {
  date_now = formatdate("YYYYMMDD", timestamp())
}

data "kubernetes_secret" "password" {
  metadata {
    name      = "mon-es-elastic-user"
    namespace = "monitoring"
  }
}

data "kubernetes_secret" "certs" {
  metadata {
    name      = "mon-es-http-certs-internal"
    namespace = "monitoring"
  }
}


resource "null_resource" "workload_readiness_check" {
  triggers = {
    restore_check = md5(file("../../references/elastic-restore/restore.py"))
  }
  provisioner "local-exec" {
    command = <<COMMAND
    python3 .. "../../references/elastic-restore/restore.py"
COMMAND
    environment = {
      ELASTICSEARCH_USERNAME = "elastic"
      ELASTICSEARCH_PASSWORD = data.kubernetes_secret.password.data.elastic
      ELASTICSEARCH_URL      = "mon-es-http"
      CA_CERT                = data.kubernetes_secret.certs.data["ca.crt"]
      WAIT_FC                = "true"
      SNAPSHOTS              = "monitoring-dr-system-${local.date_now},monitoring-lfb-system-${local.date_now}"
    }
  }
  depends_on = [module.backup-lfb]
}

