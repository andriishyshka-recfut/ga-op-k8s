resource "kubectl_manifest" "artifactory_creds" {
  yaml_body = templatefile(
    "${path.module}/../../templates/external-secrets/ExternalSecret.tftpl",
    {
      values = {
        namespace    = "flux-system"
        name         = "artifactory-client-creds"
        secret_name  = "artifactory-client-creds"
        vault_path   = "misc/artifactory/creds"
        template_data = local.artifactory_creds_template
      }
    }
  )
}

resource "kubectl_manifest" "artifactory_mtls" {
  yaml_body = templatefile(
    "${path.module}/../../templates/external-secrets/ExternalSecret.tftpl",
    {
      values = {
        namespace    = "flux-system"
        name         = "artifactory-client-mtls"
        secret_name  = "artifactory-client-mtls"
        vault_path   = "misc/artifactory/certs"
        template_data = local.artifactory_mtls_template
      }
    }
  )
}

# remove after full migration to github
resource "kubectl_manifest" "helm_creds" {
  yaml_body = templatefile(
    "${path.module}/../../templates/external-secrets/ExternalSecret.tftpl",
    {
      values = {
        namespace     = "flux-system"
        name          = "helm-credentials"
        secret_name   = "helm-credentials"
        vault_path    = "goharbor/docker_login"
        template_data = local.helm_creds_template
      }
    }
  )
}
# ---------------------------------