########## Vault
resource "vault_policy" "magescanner" {
  name = "magescanner"

  policy = <<EOT
path "secret/es-creds-compose-prod/magescanner/*" {
  capabilities = ["read","list"]
}
path "secret/mongo/production/*" {
  capabilities = ["read","list"]
}
path "secret/magescanner/google_service_account/*" {
  capabilities = ["read","list"]
}
path "secret/magescanner/geoip_secret_config/*" {
  capabilities = ["read","list"]
}
path "secret/oidc_google_prod" {
  capabilities = ["read","list"]
}
EOT
}


resource "vault_kubernetes_auth_backend_role" "magescanner_role" {
  backend                          = data.vault_auth_backend.kubernetes.path
  role_name                        = "magescanner"
  bound_service_account_names      = ["default"]
  bound_service_account_namespaces = ["magescanner"]
  token_ttl                        = 3600
  token_policies                   = ["magescanner"]
}


######### Minio

resource "kubernetes_secret" "minio_credentials_magescanner" {
  metadata {
    name      = "minio-credentials"
    namespace = "magescanner"
  }

  data = {
    "accesskey" = jsondecode(data.vault_generic_secret.minio_creds.data["magescanner"]).accessKey
    "secretkey" = jsondecode(data.vault_generic_secret.minio_creds.data["magescanner"]).secretKey
  }
}

########## Harbor

resource "kubernetes_secret" "harbor_magescanner" {
  metadata {
    name      = "harbor"
    namespace = "magescanner"
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
resource "kubernetes_secret" "apm_token_magescanner" {
  metadata {
    name      = "apm-token"
    namespace = "magescanner"
  }

  data = { "secret-token" = lookup(data.kubernetes_secret.apm_token.data, "secret-token") }

}
