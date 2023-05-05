resource "helm_release" "gitlab" {
  for_each = var.gitlab_list
  repository = "https://charts.gitlab.io/"
  chart = "gitlab"
  name  = each.key
  namespace = lookup(each.value, "namespace", local.namespace)
  timeout   = 300
  wait      = true
  atomic    = true
  version   = "6.11.2"
  values = [
    templatefile("${path.module}/gitlab-values.tftpl", merge(local.gitlab_values, {gitlab-name = each.key}))
  ]
  depends_on = [kubernetes_secret.rails_gcs,kubernetes_secret.smtp,kubernetes_secret.ssh_host_keys,kubernetes_secret.storage_config]
}

data "vault_generic_secret" "ssh_host_keys" {
  path         = "secret/gitlab/ssh-host-keys"
}

resource "kubernetes_secret" "ssh_host_keys" {
  for_each = var.gitlab_list
  metadata {
    name      = "${each.key}-ssh-host-keys"
    namespace = lookup(each.value, "namespace", local.namespace)
  }
  data = data.vault_generic_secret.ssh_host_keys.data
}

data "vault_generic_secret" "rails_gcs" {
  path         = "secret/gitlab/rails-gcs"
}

resource "kubernetes_secret" "rails_gcs" {
  for_each = var.gitlab_list
  metadata {
    name      = "${each.key}-object-storage"
    namespace = lookup(each.value, "namespace", local.namespace)
  }
  data = {
    connection = data.vault_generic_secret.rails_gcs.data.connection
  }
}

data "vault_generic_secret" "storage_config" {
  path         = "secret/gitlab/storage-config"
}

resource "kubernetes_secret" "storage_config" {
  for_each = var.gitlab_list
  metadata {
    name      = "${each.key}-backup-storage-config"
    namespace = lookup(each.value, "namespace", local.namespace)
  }
  data = {
    config = data.vault_generic_secret.storage_config.data.key
  }
}

data "vault_generic_secret" "smtp" {
  path         = "secret/gitlab/smtp"
}

resource "kubernetes_secret" "smtp" {
  for_each = var.gitlab_list
  metadata {
    name      = "${each.key}-smtp-password"
    namespace = lookup(each.value, "namespace", local.namespace)
  }
  data = {
    password = data.vault_generic_secret.smtp.data.password
  }
}

### Runner secrets
data "vault_generic_secret" "gitlab_runner" {
  path         = "secret/gitlab/runner"
}

resource "kubernetes_secret" "minio" {
  for_each = var.gitlab_list
  metadata {
    name      = "${each.key}-minio"
    namespace = lookup(each.value, "namespace", local.namespace)
  }
  data = {
    accesskey = data.vault_generic_secret.gitlab_runner.data["minio_cache_accesskey"]
    secretkey = data.vault_generic_secret.gitlab_runner.data["minio_cache_secretkey"]
  }
}

data "vault_generic_secret" "harbor_token" {
  path = "secret/goharbor/docker_login"
}


resource "kubernetes_secret" "harbor_image_pull_secrets" {
  for_each = var.gitlab_list
  metadata {
    name      = "${each.key}-harbor"
    namespace = lookup(each.value, "namespace", local.namespace)
  }

  data = {
    ".dockerconfigjson" = <<DOCKER
  {
    "auths": {
      "harbor.t.regemini.io": {
        "username": "${data.vault_generic_secret.harbor_token.data.user}",
        "password": "${data.vault_generic_secret.harbor_token.data.password}",
        "auth": "${base64encode(join("", [data.vault_generic_secret.harbor_token.data.user, ":", data.vault_generic_secret.harbor_token.data.password]))}"
       }
    }
  }
  DOCKER
  }

  type = "kubernetes.io/dockerconfigjson"
}


