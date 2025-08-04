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

  set = [
    {
      name  = "nameOverride"
      value = "${each.key}"
    },
    {
      name = "users"
      value = jsonencode({for k, v in data.vault_generic_secret.users[each.key].data: k => v})
    },
    {
      name  = "keys"
      value = jsonencode({ for k,v in data.vault_generic_secret.keys[each.key].data: k => ""})
    }
  ]
  depends_on = [kubernetes_secret.ssh_host_keys,kubernetes_secret.keys]
}

data "vault_generic_secret" "users" {
  for_each = var.server_list
  path         = "secret/sftp-server/${each.key}-users"
}

data "vault_generic_secret" "keys" {
  for_each = var.server_list
  path         = "secret/sftp-server/${each.key}-keys"
}

resource "kubernetes_secret" "keys" {
  for_each = var.server_list
  metadata {
    name       = "sftp-server-${each.key}-keys"
    namespace  = try(each.value.namespace, local.namespace)
  }

  data = data.vault_generic_secret.keys[each.key].data
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