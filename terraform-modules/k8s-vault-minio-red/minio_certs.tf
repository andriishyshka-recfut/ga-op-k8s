resource "kubectl_manifest" "clusterissuer_vault_minio" {
  yaml_body = templatefile("${path.module}/templates/clusterissuer.tftpl", { cluster = var.Cluster, color = var.Color, vault_addr = local.vaultFqdn })
}

resource "kubectl_manifest" "certificate_vault_minio" {
  yaml_body  = templatefile("${path.module}/templates/certificate.tftpl", { name = "vault-minio", namespace = local.minioNs, domain_list = local.cert_dns_names })
  depends_on = [kubectl_manifest.clusterissuer_vault_minio]
}


resource "time_sleep" "wait_60_seconds" {
  create_duration = "60s"
  depends_on      = [kubectl_manifest.certificate_vault_minio]
}

data "kubernetes_secret" "minio_tenant_ca" {
  metadata {
    name      = "tls-ssl-minio"
    namespace = "minio"
  }
  depends_on = [time_sleep.wait_60_seconds]
}

resource "kubernetes_secret" "operator_ca_secret" {
  metadata {
    name      = "operator-ca-tls"
    namespace = "minio-operator"
  }
  data = {
    "public.crt" = data.kubernetes_secret.minio_tenant_ca.data["ca.crt"]
  }
  depends_on = [data.kubernetes_secret.minio_tenant_ca]
}
