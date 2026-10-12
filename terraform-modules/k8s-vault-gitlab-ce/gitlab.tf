resource "helm_release" "gitlab" {
  for_each   = var.gitlab_list
  repository = "https://charts.gitlab.io/"
  chart      = "gitlab"
  name       = each.key
  namespace  = lookup(each.value, "namespace", local.namespace)
  timeout    = 600
  wait       = true
  atomic     = true
  version    = var.Settings.clusters[var.Cluster].versions.gitlab.helm_version
  values = [
    templatefile("${path.module}/gitlab-values.tftpl", merge(local.gitlab_values, { gitlab-name = each.key, gitlab-version = var.Settings.clusters[var.Cluster].versions.gitlab.gitlab_version }))
  ]
  depends_on = [kubernetes_secret.rails_gcs, kubernetes_secret.smtp, kubernetes_secret.ssh_host_keys, kubernetes_secret.storage_config]
  set = [
    {
      name  = "certmanager-issuer.email"
      value = var.Settings.clusters[var.Cluster].versions.gitlab.certmanager_issuer_email
      type  = "string"
    }
  ]
}

data "vault_generic_secret" "ssh_host_keys" {
  path = "secret/gitlab/ssh-host-keys"
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
  path = "secret/gitlab/rails-gcs"
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
  path = "secret/gitlab/storage-config"
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
  path = "secret/gitlab/smtp"
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
      "harbor.regemini.io": {
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


