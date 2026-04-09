resource "kubernetes_service" "minio_service" {
  count = var.Cluster == "production" ? 1 : 0
  metadata {
    name      = "minio"
    namespace = local.namespace
  }
  spec {
    cluster_ip       = "None"
    session_affinity = "None"
    port {
      name        = "minio"
      protocol    = "TCP"
      port        = 9000
      target_port = 9000
    }
  }
}

resource "kubernetes_endpoints" "minio_endpoint" {
  count = var.Cluster == "production" ? 1 : 0
  metadata {
    name      = kubernetes_service.minio_service[0].metadata[0].name
    namespace = local.namespace
    labels = {
      "kubernetes.io/service-name" = kubernetes_service.minio_service[0].metadata[0].name
    }
  }

  subset {
    address {
      ip = var.Settings.internal_static_ips.minio.ip
    }

    port {
      name     = "minio"
      port     = 9000
      protocol = "TCP"
    }
  }
}


resource "kubernetes_service" "minio_helm_service" {
  count = var.Cluster == "production" ? 1 : 0
  metadata {
    name      = "minio"
    namespace = "minio-helm"
  }
  spec {
    cluster_ip       = "None"
    session_affinity = "None"
    port {
      name        = "minio"
      protocol    = "TCP"
      port        = 9000
      target_port = 9000
    }
  }
}

resource "kubernetes_endpoints" "minio_helm_endpoint" {
  count = var.Cluster == "production" ? 1 : 0
  metadata {
    name      = kubernetes_service.minio_helm_service[0].metadata[0].name
    namespace = "minio-helm"
    labels = {
      "kubernetes.io/service-name" = kubernetes_service.minio_helm_service[0].metadata[0].name
    }
  }

  subset {
    address {
      ip = var.Settings.internal_static_ips.minio-helm.ip
    }

    port {
      name     = "minio"
      port     = 9000
      protocol = "TCP"
    }
  }
}

data "vault_pki_secret_backend_issuer" "pki_minio" {
  backend    = "pki-minio"
  issuer_ref = "default"
}
resource "kubernetes_secret" "minio_ca_cert" {
  for_each = local.logstash_list
  metadata {
    name      = "minio-ca-certs"
    namespace = each.value.namespace
  }
  data = {
    "ca.crt" = data.vault_pki_secret_backend_issuer.pki_minio.certificate
  }
  depends_on = [data.vault_pki_secret_backend_issuer.pki_minio]
}
