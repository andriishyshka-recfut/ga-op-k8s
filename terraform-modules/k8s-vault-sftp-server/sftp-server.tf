locals {
  sftpCronJobValues = yamldecode(file("${path.module}/sftp-server/values.yaml"))
}

resource "helm_release" "sftp-server" {
  for_each     = var.server_list
  name         = "sftp-server-${each.key}"
  chart        = "${path.module}/sftp-server"
  wait         = true
  atomic       = true
  namespace    = try(each.value.namespace, local.namespace)
  reset_values = true

  set {
    name  = "nameOverride"
    value = "${each.key}"
  }
  set {
    name = "users"
    value = data.vault_generic_secret.users_secret[each.key].data["users"]
  }
  set {
    name  = "keys"
    value = data.vault_generic_secret.users_secret[each.key].data["keys"]
  }
  depends_on = [kubernetes_secret.ssh_host_keys]
}

data "vault_generic_secret" "users_secret" {
  for_each = var.server_list
  path       = "secret/sftp-server/${each.key}-users"
}

data "vault_generic_secret" "ssh_host_keys" {
  for_each = var.server_list
  path         = "secret/sftp-server/${each.key}-ssh-host-keys"
}

resource "kubernetes_secret" "ssh_host_keys" {
  for_each = var.server_list
  metadata {
    name       = "sftp-server-${each.key}-ssh-host-keys"
    namespace  = try(each.value.namespace, local.namespace)
  }

  data = data.vault_generic_secret.ssh_host_keys[each.key].data
}
