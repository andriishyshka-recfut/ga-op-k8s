locals {
  sftpCronJobValues = yamldecode(file("${path.module}/sftp-server/values.yaml"))
}

resource "helm_release" "sftp-server" {
  for_each     = var.server_list
  name         = "sftp-server-${each.key}"
  chart        = "${path.module}/sftp-server"
  #wait         = true
  #atomic       = true
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
}


data "vault_generic_secret" "users_secret" {
  for_each = var.server_list
  path         = "secret/sftp-server/${each.key}-users"
}





/*
resource "kubernetes_secret" "users" {
  for_each = var.server_list
  metadata {
    name       = "sftp-server-${each.key}-users"
    namespace  = try(each.value.namespace, local.namespace)
  }

  data = {
  for key, value in data.vault_generic_secret.users_secret[each.key].data : key => base64encode(value)
  }
}


resource "kubernetes_secret" "ssh_key" {
  for_each = var.server_list
  metadata {
    name       = "sftp-server-${each.key}-keys"
    namespace  = try(each.value.namespace, local.namespace)
  }

  data = {
  for k, v in data.vault_generic_secret.users_secret[each.key].data : k => base64encode(v)
  }
}
*/