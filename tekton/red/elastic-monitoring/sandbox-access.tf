resource "kubectl_manifest" "elastic_monitoring_psc" {
  yaml_body = yamlencode({
    apiVersion = "networking.gke.io/v1"
    kind       = "ServiceAttachment"

    metadata = {
      name      = "elastic-mon-red-psc"
      namespace = "monitoring"
    }

    spec = {
      connectionPreference = "ACCEPT_MANUAL"

      consumerAllowList = [{
        project         = "ardent-rarity-239115"
        connectionLimit = 1
      }]

      natSubnets   = ["psc-elastic-nat"]
      proxyProtocol = false

      resourceRef = {
        kind = "Service"
        name = "elastic-mon-red-internal-ingress"
      }
    }
  })
}