resource "kubernetes_service_account" "vault_sa" {
  metadata {
    name      = "vault-sa"
    namespace = "kube-system"
  }
}

resource "kubernetes_cluster_role_binding" "vault_sa" {
  metadata {
    name = "vault-sa"
  }
  role_ref {
    api_group = "rbac.authorization.k8s.io"
    kind      = "ClusterRole"
    name      = "system:auth-delegator"
  }
  subject {
    kind      = "ServiceAccount"
    name      = "vault-sa"
    namespace = "kube-system"
  }
}

resource "vault_mount" "pki_elastic_int" {
  path                  = "pki-elastic-int"
  type                  = "pki"
  description           = "Elastic inernal certificates"
  max_lease_ttl_seconds = 31708800
}

resource "vault_pki_secret_backend_root_cert" "elastic_int" {
  depends_on           = [vault_mount.pki_elastic_int]
  backend              = vault_mount.pki_elastic_int.path
  type                 = "internal"
  common_name          = "Red Cluster Elastic"
  ttl                  = "31708800"
  format               = "pem"
  private_key_format   = "der"
  key_type             = "rsa"
  key_bits             = 2048
  exclude_cn_from_sans = true
  ou                   = "IT"
  organization         = "Gemini Advisory LLC"
  country              = "US"
  locality             = "Miami"
  province             = "FL"
}

resource "vault_pki_secret_backend_role" "role" {
  depends_on         = [vault_pki_secret_backend_root_cert.elastic_int]
  backend            = vault_mount.pki_elastic_int.path
  name               = "elastic"
  max_ttl            = 32832000
  key_type           = "rsa"
  key_bits           = 2048
  allowed_domains    = [
    "mon-es-http",  
    "mon-es-http.monitoring.svc", 
    "elastic-es-http", 
    "elastic-es-http.elastic.svc", 
    "elastic-es-http.elastic", 
    "elasticsearch-coor", 
    "red-coor.elastic.svc", 
    "red-coor", 
    "red-coor.elastic.svc",
    "*.red-ingest-headless.elastic.svc",
    "*.red-data-headless.elastic.svc",
    "*.red-coor-headless.elastic.svc",
    "*.red-master-headless.elastic.svc"
  ]
  allow_subdomains   = true
  allow_localhost    = true
  allow_bare_domains = true
  ou                 = ["IT"]
  organization       = ["Gemini Advisory LLC"]
  country            = ["US"]
  locality           = ["Miami"]
  province           = ["FL"]
}

data "kubernetes_service_account" "cert_manager" {
  metadata {
    name      = "production-cert-manager"
    namespace = "kube-system"
  }
}

data "kubernetes_secret" "cert_manager" {
  metadata {
    name      = data.kubernetes_service_account.cert_manager.default_secret_name
    namespace = "kube-system"
  }
}

data "kubernetes_secret" "vault_sa" {
  metadata {
    name      = local.vault_auth_secret_name
    namespace = "kube-system"
  }
}

resource "vault_auth_backend" "k8s_production_red" {
  type = "kubernetes"
  path = "k8s-production-red"
  tune {
    max_lease_ttl = "2764800s"
  }
}

resource "vault_kubernetes_auth_backend_config" "k8s_production_red" {
  backend                = vault_auth_backend.k8s_production_red.path
  kubernetes_host        = vault_generic_secret.cluster_token.data["HOST"]
  kubernetes_ca_cert     = data.kubernetes_secret.vault_sa.data["ca.crt"]
  token_reviewer_jwt     = data.kubernetes_secret.vault_sa.data["token"]
  issuer                 = "kubernetes/serviceaccount"
  disable_local_ca_jwt   = "true"
  disable_iss_validation = "true"
}

resource "vault_kubernetes_auth_backend_role" "k8s_production_red" {
  backend                          = vault_auth_backend.k8s_production_red.path
  role_name                        = "cert-manager"
  bound_service_account_names      = ["vault-sa"]
  bound_service_account_namespaces = ["kube-system"]
  token_ttl                        = 0
  token_policies                   = ["pki", "default"]
}

resource "vault_jwt_auth_backend" "jwt_red" {
  path               = "jwt-red"
  oidc_discovery_url = "https://container.googleapis.com/v1/projects/orbital-wording-233917/locations/us-east4/clusters/production-red"
}

# resource "vault_jwt_auth_backend_role" "jwt_red" {
#   backend         = vault_jwt_auth_backend.jwt_red.path
#   role_name       = "cert-manager-production-red"
#   token_policies  = ["pki"]
#   bound_audiences = ["https://container.googleapis.com/v1/projects/orbital-wording-233917/locations/us-east4/clusters/production-red"]
#   bound_subject   = "system:serviceaccount:kube-system:vault-sa"
#   user_claim      = "sub"
#   role_type       = "jwt"
# }


resource "kubernetes_manifest" "vault_certmanager" {
  manifest = {
    "apiVersion" = "cert-manager.io/v1"
    "kind"       = "ClusterIssuer"
    "metadata" = {
      "name" = "vault-issuer"
    }
    "spec" = {
      "vault" = {
        "auth" = {
          "kubernetes" = {
            "mountPath" = "/v1/auth/k8s-production-red"
            "role"      = "cert-manager"
            "secretRef" = {
              "key"  = "token"
              "name" = local.vault_auth_secret_name
            }
          }
        }
        "path"   = "pki-elastic-int/sign/elastic"
        "server" = "https://vault.p.regemini.io"
      }
    }
  }
  field_manager {
    force_conflicts = true
  }

}
