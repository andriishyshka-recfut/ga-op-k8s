locals {
  beatsValues = yamldecode(file("${path.module}/beats_values.yaml"))
}

variable "Settings" {}
variable "Color" {}
variable "Cluster" {}
locals {
  version = var.Settings.clusters[var.Cluster][var.Color].elasticsearch.cluster.elastic
}

resource "helm_release" "beat" {
  name      = "beats"
  chart     = "${path.module}/beats"
  wait      = true
  atomic    = true
  namespace = "elastic"
  values = [
    yamlencode(local.beatsValues)
  ]
  set {
    name  = "beatsVersion"
    value = local.version
  }

}
