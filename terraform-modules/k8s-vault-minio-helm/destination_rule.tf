resource "kubernetes_manifest" "destinationrule_minio_helm_minio_helm_tls" {
  manifest = {
    "apiVersion" = "networking.istio.io/v1alpha3"
    "kind" = "DestinationRule"
    "metadata" = {
      "name" = "minio-helm-tls"
      "namespace" = local.minioNs
    }
    "spec" = {
      "host" = "minio-tenant-console.minio-helm.svc.cluster.local"
      "trafficPolicy" = {
        "portLevelSettings" = [
          {
            "port" = {
              "number" = 9443
            }
            "tls" = {
              "insecureSkipVerify" = true
              "mode" = "SIMPLE"
            }
          },
        ]
      }
    }
  }
  depends_on = [ helm_release.minio_tenant ]
}



resource "kubernetes_manifest" "destinationrule_minio_helm_minio_helm_tls_api" {
  manifest = {
    "apiVersion" = "networking.istio.io/v1alpha3"
    "kind" = "DestinationRule"
    "metadata" = {
      "name" = "minio-helm-tls-api"
      "namespace" = local.minioNs
    }
    "spec" = {
      "host" = "minio-tenant-hl.minio-helm.svc.cluster.local"
      "trafficPolicy" = {
        "portLevelSettings" = [
          {
            "port" = {
              "number" = 9000
            }
            "tls" = {
              "insecureSkipVerify" = true
              "mode" = "SIMPLE"
            }
          },
        ]
      }
    }
  }
  depends_on = [ helm_release.minio_tenant ]
}