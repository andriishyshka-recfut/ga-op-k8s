
data "vault_generic_secret" "gitlab_token" {
  path = "secret/misc/gitlab/token/read_repo"
}

resource "kubernetes_secret" "gitlab_token" {
  metadata {
    name      = "gitlab-token"
    namespace = local.namespace
  }

  data = {
    "username" = data.vault_generic_secret.gitlab_token.data.username
    "password" = data.vault_generic_secret.gitlab_token.data.token
  }

}

data "vault_generic_secret" "helm_creds" {
  path = "secret/goharbor/docker_login"
}

resource "kubernetes_secret" "helm_creds" {
  metadata {
    name      = "helm-credentials"
    namespace = local.namespace
  }
  data = {
    "username" = data.vault_generic_secret.helm_creds.data.user
    "password" = data.vault_generic_secret.helm_creds.data.password
  }


}
