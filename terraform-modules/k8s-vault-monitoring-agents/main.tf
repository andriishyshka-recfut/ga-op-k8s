locals {

  beatsValues = yamldecode(file("${path.module}/beats_values.yaml"))

}


variable "Settings" {}
variable "Color" {}
variable "Cluster" { }
locals{
  version = var.Settings[var.Cluster][var.Color].elasticsearch.cluster.monitoring
 }



resource "helm_release" "beat" {
  name      = "beats"
  chart     = "${path.module}/beats"
  wait      = true
  atomic    = true
  namespace = "monitoring"
  values = [
    yamlencode(local.beatsValues)
  ]
  set {
    name = "beatsVersion"
    value = local.version
  }

}
