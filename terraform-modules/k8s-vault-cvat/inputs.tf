variable "Cluster" {}
variable "Color" {}
variable "Settings" {}

locals {
  namespace     = "cvat"
  volume_size   = "20Gi"
  affinity_list = tolist(["backend", "frontend", "opa", "kvrocks", "postgresql", "redis"])
  pvc_list      = ["backend.server", "backend.worker.export", "backend.worker.import", "backend.worker.annotation", "backend.utils"]

}
