locals {
  destination_rules = {
    minio-tls = {
      host               = "minio-tenant-console.minio.svc.cluster.local"
      port               = 9443
      insecureSkipVerify = true
    }
    minio-tls-api = {
      host               = "minio-tenant-hl.minio.svc.cluster.local"
      port               = 9000
      insecureSkipVerify = true
    }
    minio-tls-api-ingress = {
      host               = "minio.minio.svc.cluster.local"
      port               = 9000
      insecureSkipVerify = true
    }
  }
}
resource "kubectl_manifest" "minio_helm" {
  for_each   = local.destination_rules
  yaml_body  = templatefile("../../../templates/istio/DestinationRule.tftpl", { values = each.value, name = each.key, namespace = local.minioNs })
  depends_on = [helm_release.minio_tenant]
}
