locals {
  beatsValues = yamldecode(file("${path.module}/beats_values.yaml"))
}

variable "Settings" {}
variable "Color" {}
variable "Cluster" {}
locals {
  version = var.Settings.clusters[var.Cluster][var.Color].elasticsearch.cluster.elastic
}

data "kubernetes_secret" "es_pass" {
  metadata {
    name      = "elastic-es-elastic-user"
    namespace = "elastic"
  }
}

