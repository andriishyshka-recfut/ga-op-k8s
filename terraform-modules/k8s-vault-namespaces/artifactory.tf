data "vault_kv_secret_v2" "artifactory_creds" {
  mount = "secret"
  name = "misc/artifactory/creds"
}


resource "kubernetes_secret" "artifactory_image_pull_secrets" {
  for_each = local.injectArtifactoryImagePullSecrets
  metadata {
    name      = "artifactory-creds"
    namespace = each.key
  }

  data = {
    ".dockerconfigjson" = <<DOCKER
{
  "auths": {
    "repo-external.recfut.com": {
      "username": "${data.vault_kv_secret_v2.artifactory_creds.data.user}",
      "password": "${data.vault_kv_secret_v2.artifactory_creds.data.password}"
     }
    }
  }
DOCKER
  }

  type = "kubernetes.io/dockerconfigjson"
  depends_on = [
    kubernetes_namespace.ns
  ]

}