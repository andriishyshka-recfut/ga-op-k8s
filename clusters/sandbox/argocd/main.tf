provider "vault" {
  address = "https://vault.infra.digaweb.com"
}

data "vault_generic_secret" "k8s_auth" {
  path = "secret/kubernetes-sandbox"
}

provider "helm" {
  # alias = "helm"
  kubernetes {
    load_config_file       = false
    host                   = data.vault_generic_secret.k8s_auth.data.HOST
    cluster_ca_certificate = data.vault_generic_secret.k8s_auth.data.CLUSTER_CA_CERTIFICATE
    token                  = data.vault_generic_secret.k8s_auth.data.k8s_sa_token
  }
}

provider "kubernetes" {
  # alias                  = "kubernetes"
  load_config_file       = false
  host                   = data.vault_generic_secret.k8s_auth.data.HOST
  cluster_ca_certificate = data.vault_generic_secret.k8s_auth.data.CLUSTER_CA_CERTIFICATE
  token                  = data.vault_generic_secret.k8s_auth.data.k8s_sa_token
}

data "vault_generic_secret" "gitlab_token" {
  path = "secret/gitlab"
}

resource "kubernetes_secret" "gitlab-token" {
  metadata {
    name      = "gitlab-token"
    namespace = "argocd"
  }

  data = {
    "username" = data.vault_generic_secret.gitlab_token.data.username
    "password" = data.vault_generic_secret.gitlab_token.data.token_read_repo
  }

}



data "vault_generic_secret" "oidc_secrets" {
  path = "secret/oidc_google_test"
}

resource "helm_release" "argocd" {
  name = "argocd"
  #chart = "${path.module}/umbrella-vault"
  chart      = "argo-cd"
  repository = "https://argoproj.github.io/argo-helm"
  #version           = "0.1.0"
  namespace         = "argocd"
  dependency_update = "true"

  values = [
    templatefile("${path.root}/values.tmpl",
      {
        CLIENT_ID     = data.vault_generic_secret.oidc_secrets.data.oidc_client_id
        CLIENT_SECRET = data.vault_generic_secret.oidc_secrets.data.oidc_client_secret
      }
    )
  ]
  depends_on = [
    kubernetes_secret.gitlab-token
  ]
}
