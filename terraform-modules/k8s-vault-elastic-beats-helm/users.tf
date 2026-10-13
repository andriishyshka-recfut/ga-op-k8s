resource "random_password" "filebeat_password" {
  for_each = var.filebeats_settings
  length   = 24
  special  = false
}

resource "random_password" "metricbeat_password" {
  for_each = var.metricbeats_setttings
  length   = 24
  special  = false
}

resource "random_password" "auditbeat_password" {
  for_each = var.auditbeats_setttings
  length   = 24
  special  = false
}

data "vault_generic_secret" "logstash_es_creds" {
  for_each = var.logstash_list
  path     = "secret/logstash/${each.key}"
}

resource "kubernetes_secret" "filebeat_creds" {
  for_each = var.filebeats_settings
  metadata {
    name      = each.value.filebeat_pass_secretname
    namespace = each.value.namespace
  }
  data = {
    "password" = random_password.filebeat_password[each.key].result
  }
  depends_on = [random_password.filebeat_password]
}

resource "kubernetes_secret" "metricbeat_creds" {
  for_each = var.metricbeats_setttings
  metadata {
    name      = "${each.key}-credentials"
    namespace = local.elasticSettings.globalSettings.namespace
  }
  data = {
    "username" = "${each.key}-user"
    "password" = random_password.metricbeat_password[each.key].result
  }
}

resource "kubernetes_secret" "auditbeat_creds" {
  for_each = var.auditbeats_setttings
  metadata {
    name      = "${each.key}-credentials"
    namespace = local.elasticSettings.globalSettings.namespace
  }
  data = {
    "username" = "${each.key}-user"
    "password" = random_password.auditbeat_password[each.key].result
  }
}

data "vault_generic_secret" "filebeat_elastic_pass" {
  for_each = local.filebeats_with_vault_pass

  path = local.elasticSettings.globalSettings.storePassVault
}

resource "kubernetes_secret" "filebeat_elastic_pass" {
  for_each = local.filebeats_with_vault_pass

  metadata {
    name      = "${each.value.name}-elastic-credentials"
    namespace = each.value.namespace
  }

  data = {
    "elastic" = data.vault_generic_secret.filebeat_elastic_pass[each.key].data["elastic"]
  }
}

data "vault_generic_secret" "auditbeat_elastic_pass" {
  for_each = local.auditbeats_with_vault_pass

  path = local.elasticSettings.globalSettings.storePassVault
}

resource "kubernetes_secret" "auditbeat_elastic_pass" {
  for_each = local.auditbeats_with_vault_pass

  metadata {
    name      = "${each.value.name}-elastic-credentials"
    namespace = each.value.namespace
  }

  data = {
    "elastic" = data.vault_generic_secret.auditbeat_elastic_pass[each.key].data["elastic"]
  }
}
data "vault_generic_secret" "metricbeat_elastic_pass" {
  for_each = local.metricbeats_with_vault_pass

  path = local.elasticSettings.globalSettings.storePassVault
}

resource "kubernetes_secret" "metricbeat_elastic_pass" {
  for_each = local.metricbeats_with_vault_pass

  metadata {
    name      = "${each.value.name}-elastic-credentials"
    namespace = each.value.namespace
  }

  data = {
    "elastic" = data.vault_generic_secret.metricbeat_elastic_pass[each.key].data["elastic"]
  }
}

data "vault_generic_secret" "prod_mon_creds" {
  count = var.Cluster == "sandbox" ? 1 : 0 
  path     = "secret/misc/red-mon-elasticsearch/credentials"
}

resource "kubernetes_secret" "prod_mon_creds" {
  count = var.Cluster == "sandbox" ? 1 : 0 

  metadata {
    name      = "prod-mon-elastic-creds"
    namespace = "monitoring"
  }

  data = {
    data.vault_generic_secret.prod_mon_creds[count.index].data["username"] = data.vault_generic_secret.prod_mon_creds[count.index].data["password"]
  }
}

resource "kubernetes_job" "filebeats_users" {
  for_each = var.filebeats_settings
  metadata {
    name      = "${each.value.name}-filebeat-user"
    namespace = each.value.namespace
  }
  spec {
    template {
      metadata {

        annotations = {
          "sidecar.istio.io/inject" = "false"
        }
      }
      spec {
        container {
          name    = "post-install"
          image   = "curlimages/curl"
          command = ["sh", "-c", local.filebeats_jobs[each.key]]
          env {
            name = "ES_PASSWORD"
            value_from {
              secret_key_ref {
                name = lookup(each.value, "elastic_pass_from_vault", false) ? "${each.value.name}-elastic-credentials" : each.value.elastic_pass_secretname
                key  = "elastic"
              }
            }
          }
          resources {
            requests = {
              cpu    = "100m"
              memory = "100M"
            }
          }
        }
        restart_policy = "Never"
      }
    }
    backoff_limit = 4
  }
  wait_for_completion = true
  timeouts {
    create = "5m"
    update = "5m"
  }
}



resource "kubernetes_job" "auditbeat_users" {
  for_each = var.auditbeats_setttings
  metadata {
    name      = "${lookup(each.value, "name", each.key)}-user"
    namespace = each.value.namespace
  }
  spec {
    template {
      metadata {

        annotations = {
          "sidecar.istio.io/inject" = "false"
        }
      }
      spec {
        container {
          name  = "post-install"
          image = "curlimages/curl"
          command = ["sh", "-c", templatefile("${path.module}/templates/users/auditbeat_user.tftpl", {
            settings = each.value
            password = random_password.auditbeat_password[each.key].result
            user     = "${each.key}-user"
          })]
          env {
            name = "ES_PASSWORD"
            value_from {
              secret_key_ref {
                name = lookup(each.value, "elastic_pass_from_vault", false) ? "${each.value.name}-elastic-credentials" : each.value.elastic_pass_secretname
                key  = "elastic"
              }
            }
          }
          resources {
            requests = {
              cpu    = "100m"
              memory = "100M"
            }
          }
        }
        restart_policy = "Never"
      }
    }
    backoff_limit = 4
  }
  wait_for_completion = true
  timeouts {
    create = "5m"
    update = "5m"
  }
}


resource "kubernetes_job" "metricbeat_users" {
  for_each = var.metricbeats_setttings
  metadata {
    name      = "${lookup(each.value, "name", each.key)}-user"
    namespace = each.value.namespace
  }
  spec {
    template {
      metadata {

        annotations = {
          "sidecar.istio.io/inject" = "false"
        }
      }
      spec {
        container {
          name  = "post-install"
          image = "curlimages/curl"
          command = ["sh", "-c", templatefile("${path.module}/templates/users/metricbeat_user.tftpl", {
            settings = each.value
            password = random_password.metricbeat_password[each.key].result
            user     = "${each.key}-user"
          })]
          env {
            name = "ES_PASSWORD"
            value_from {
              secret_key_ref {
                name = lookup(each.value, "elastic_pass_from_vault", false) ? "${each.value.name}-elastic-credentials" : each.value.elastic_pass_secretname
                key  = "elastic"
              }
            }
          }
          resources {
            requests = {
              cpu    = "100m"
              memory = "100M"
            }
          }
        }
        restart_policy = "Never"
      }
    }
    backoff_limit = 4
  }
  wait_for_completion = true
  timeouts {
    create = "5m"
    update = "5m"
  }
}
