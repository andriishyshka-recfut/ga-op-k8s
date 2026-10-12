resource "helm_release" "apm" {
  name      = "apm"
  namespace = local.esValues.namespace
  chart     = "${path.module}/apm"
  wait      = true
  atomic    = true
  values = [
    yamlencode(local.esValues)
  ]
  set = [
    {
      name  = "appVersion"
      value = local.version
    },
    {
      name  = "count"
      value = 2
    }
  ]
}

resource "null_resource" "ansible_validate_resources" {

  triggers = {
    playbook_contents = md5(file("${path.module}/../../ansible/validate_eck.yml"))
    helm_release      = helm_release.apm.id
  }
  provisioner "local-exec" {
    command = <<COMMAND
    cd ${path.module}/../../ansible &&\
    ansible-playbook validate_eck.yml

COMMAND
    environment = merge(local.ansibleEnvs, {
      name       = "apm-${local.esValues.esName}"
      kind       = "ApmServer"
      apiVersion = "apm.k8s.elastic.co/v1"
    })
  }
  depends_on = [
    helm_release.apm
  ]
}

# resource "vault_generic_secret" "apm_creds" {
#   count = local.apmCredsToggle
#   path  = "secret/apm/${local.esValues.esName}-${var.Color}"

#   data_json = <<EOT
#   {
#     "token": "${lookup(data.kubernetes_secret.apm_token[0].data, "secret-token")}"
#   }
# EOT
# }

# resource "vault_generic_secret" "apm_creds_red" {
#   count = local.apmCredsToggle
#   path  = "secret/apm/${local.esValues.esName}-red"

#   data_json = <<EOT
#   {
#     "secret-token": "${lookup(data.kubernetes_secret.apm_token[0].data, "secret-token")}"
#   }
# EOT
# }
