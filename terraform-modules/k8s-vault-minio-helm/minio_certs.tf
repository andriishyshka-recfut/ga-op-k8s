resource "kubernetes_manifest" "clusterissuer_vault_minio" {
  manifest = {
    "apiVersion" = "cert-manager.io/v1"
    "kind"       = "ClusterIssuer"
    "metadata" = {
      "name" = "vault-minio"
    }
    "spec" = {
      "vault" = {
        "auth" = {
          "kubernetes" = {
            "mountPath" = "/v1/auth/k8s-${var.Cluster}-${var.Color}"
            "role"      = "cert-manager"
            "secretRef" = {
              "key"  = "token"
              "name" = "sa-${var.Cluster}-cert-manager"
            }
          }
        }
        "path"   = "pki-minio/sign/minio"
        "server" = "${local.vaultFqdn}"
      }
    }
  }
}

resource "kubernetes_manifest" "certificate_minio_helm_vault_minio" {
  manifest = {
    "apiVersion" = "cert-manager.io/v1"
    "kind"       = "Certificate"
    "metadata" = {
      "name"      = "vault-minio"
      "namespace" = "minio-helm"
    }
    "spec" = {
      "commonName" = "minio.minio-helm.svc.cluster.local"
      "dnsNames" = [
        "*.minio-helm.svc.cluster.local",
        "*.minio.minio-helm.svc.cluster.local",
        "*.minio-tenant-console.minio-helm.svc.cluster.local",
        "*.minio-tenant-hl.minio-helm.svc.cluster.local"
      ]
      "issuerRef" = {
        "kind" = "ClusterIssuer"
        "name" = "vault-minio"
      }
      "secretName" = "tls-ssl-minio"
    }
  }
  depends_on = [kubernetes_manifest.clusterissuer_vault_minio]
}

data "kubernetes_secret" "minio_tenant_ca" {
  metadata {
    name      = "tls-ssl-minio"
    namespace = "minio-helm"
  }
  depends_on = [kubernetes_manifest.certificate_minio_helm_vault_minio]
}

resource "kubernetes_secret" "operator_ca_secret" {
  metadata {
    name      = "operator-ca-tls"
    namespace = "minio-operator"
  }
  data = {
    "public.crt" = data.kubernetes_secret.minio_tenant_ca.data["ca.crt"]
  }

}
