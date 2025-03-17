resource "kubernetes_manifest" "virtualservice_minio_helm_minio_helm_virtualservice" {
  manifest = {
    "apiVersion" = "networking.istio.io/v1beta1"
    "kind" = "VirtualService"
    "metadata" = {
      "name" = "minio-helm-virtualservice"
      "namespace" = "minio-helm"
    }
    "spec" = {
      "gateways" = [
        "istio-ingress/minio-helm-wg",
      ]
      "hosts" = [
        "${local.minioFqdn}",
      ]
      "http" = [
        {
          "match" = [
            {
              "uri" = {
                "prefix" = "/"
              }
            },
          ]
          "route" = [
            {
              "destination" = {
                "host" = "minio-tenant-console"
                "port" = {
                  "number" = 9443
                }
              }
            },
          ]
        },
      ]
    }
  }
}
