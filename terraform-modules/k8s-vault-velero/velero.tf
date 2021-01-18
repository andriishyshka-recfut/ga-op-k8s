
# data "google_service_account" "velero_sa" {
#   account_id = "velero"
# }
# resource "google_service_account_key" "velero_key" {
#   service_account_id = data.google_service_account.velero_sa.name
# }

data "vault_generic_secret" "root_credentials_from_vault" {
  path = local.vaultRootCredentialsPath
}

resource "kubernetes_secret" "velero_credentials_kubernetes_secret" {
  metadata {
    name      = "velero-credentials"
    namespace = local.veleroNs
  }

  data = {
    # "gcs_key.json" = base64decode(google_service_account_key.velero_key.private_key)
    cloud = <<EOF
    [default]
    aws_access_key_id=${data.vault_generic_secret.root_credentials_from_vault.data.accessKey}
    aws_secret_access_key=${data.vault_generic_secret.root_credentials_from_vault.data.secretKey}
EOF
  }

}

data "google_project" "current_project" {
}

resource "helm_release" "velero" {
  name              = "velero"
  chart             = "velero"
  repository        = "https://vmware-tanzu.github.io/helm-charts"
  namespace         = local.veleroNs
  dependency_update = "true"

  values = [
    templatefile("${path.module}/velero-helm-values.yaml.tmpl",
      {
        ProjectId = split("/", data.google_project.current_project.id)[1]
        Cluster   = var.Cluster
      }
    )
  ]
  depends_on = [
    kubernetes_secret.velero_credentials_kubernetes_secret,
  ]
}
