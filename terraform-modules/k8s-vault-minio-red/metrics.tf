resource "null_resource" "minio_prometheus_token" {
  provisioner "local-exec" {
    command = <<-EOT
      cd ${path.module}/../../ansible
      ansible-playbook minio-prometheus-token.yml \
        -e minio_access_key='${data.vault_generic_secret.root_credentials_from_vault.data.accessKey}' \
        -e minio_secret_key='${data.vault_generic_secret.root_credentials_from_vault.data.secretKey}'
    EOT
  }

  #depends_on = [helm_release.minio_tenant]

  triggers = {
    tenant = "red"
  }
}

data "vault_generic_secret" "minio_prometheus_token" {
  path = "secret/misc/minio/prometheus/token"

  depends_on = [null_resource.minio_prometheus_token]
}

resource "kubernetes_secret" "minio_prometheus_token" {
  metadata {
    name      = "minio-prometheus-token"
    namespace = "monitoring"
  }

  data = {
    token = data.vault_generic_secret.minio_prometheus_token.data["token"]
  }

  type = "Opaque"
}