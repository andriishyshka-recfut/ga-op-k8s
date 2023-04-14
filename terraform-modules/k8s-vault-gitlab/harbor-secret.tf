data "vault_generic_secret" "harbor_token" {
  path = "secret/goharbor/docker_login"
}


resource "kubernetes_secret" "harbor_image_pull_secrets" {
  metadata {
    name      = "harbor"
    namespace = "gitlab"
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
