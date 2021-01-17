########## Vault
data "vault_auth_backend" "kubernetes" {
  path = "k8s-production-blue"
}

resource "vault_policy" "maid" {
  name = "maid"

  policy = <<EOT
path "secret/es-creds-compose-prod/maid/*" {
  capabilities = ["read","list"]
}
path "secret/oidc_google_prod" {
  capabilities = ["read","list"]
}
EOT
}


resource "vault_kubernetes_auth_backend_role" "maid_role" {
  backend                          = data.vault_auth_backend.kubernetes.path
  role_name                        = "maid"
  bound_service_account_names      = ["default"]
  bound_service_account_namespaces = ["maid"]
  token_ttl                        = 3600
  token_policies                   = ["maid"]
}


######### Minio
data "vault_generic_secret" "minio_creds" {
  path = "secret/minio/users"
}

resource "kubernetes_secret" "minio_credentials" {
  metadata {
    name      = "minio-credentials"
    namespace = "maid"
  }

  data = {
    "accesskey" = jsondecode(data.vault_generic_secret.minio_creds.data["maid"]).accessKey
    "secretkey" = jsondecode(data.vault_generic_secret.minio_creds.data["maid"]).secretKey
  }
}

########## Harbor

data "vault_generic_secret" "harbor_token" {
  path = "secret/goharbor/docker_login"
}


resource "kubernetes_secret" "harbor_maid" {
  metadata {
    name      = "harbor"
    namespace = "maid"
  }

  data = {
    ".dockerconfigjson" = <<DOCKER
{
  "auths": {
    "harbor.infra.digaweb.com": {
      "username": "${data.vault_generic_secret.harbor_token.data.user}",
      "password": "${data.vault_generic_secret.harbor_token.data.password}"
     }
    }
  }
DOCKER
  }

  type = "kubernetes.io/dockerconfigjson"

}

############## APM
data "kubernetes_secret" "apm_token" {
  metadata {
    name      = "apm-monitoring-apm-token"
    namespace = "monitoring"
  }
  depends_on = [module.monitoring-elastic]
}

resource "kubernetes_secret" "apm_token_maid" {
  metadata {
    name      = "apm-token"
    namespace = "maid"
  }

  data = { "secret-token" = lookup(data.kubernetes_secret.apm_token.data, "secret-token") }

}
