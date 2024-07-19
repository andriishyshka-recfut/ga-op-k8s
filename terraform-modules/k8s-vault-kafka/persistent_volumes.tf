data "google_compute_disk" "kafka_data_pv" {
  count   = local.pv_disk_count
  name    = "kafka-data-${count.index}"
  project = var.Settings.gcpProject
  zone    = element([for i in range(local.pv_disk_count) : element(local.zones, i % 3)], count.index)
}

data "google_compute_disk" "kafka_controller_pv" {
  count   = local.pv_disk_count
  name    = "kafka-controller-${count.index}"
  project = var.Settings.gcpProject
  zone    = element([for i in range(local.pv_disk_count) : element(local.zones, i % 3)], count.index)
}


resource "kubernetes_persistent_volume" "kafka_data_pv" {
  count = local.pv_disk_count
  metadata {
    name = "kafka-data-${count.index}-pv"
    labels = {
      target = "kafka-data"
    }
  }
  spec {
    capacity = {
      storage = data.google_compute_disk.kafka_data_pv[count.index].size
    }
    access_modes = ["ReadWriteOnce"]
    claim_ref {
      namespace = local.kafkaNs
      name      = "data-0-kafka-cluster-kafka-${sum([count.index, local.pv_disk_count])}"
    }
    persistent_volume_source {
      csi {
        driver        = "pd.csi.storage.gke.io"
        volume_handle = "projects/${var.Settings.gcpProject}/zones/${data.google_compute_disk.kafka_data_pv[count.index].zone}/disks/kafka-data-${count.index}"
      }
    }
    node_affinity {
      required {
        node_selector_term {
          match_expressions {
            key      = "topology.gke.io/zone"
            operator = "In"
            values   = [data.google_compute_disk.kafka_data_pv[count.index].zone]
          }
        }
      }
    }
  }
}

resource "kubernetes_persistent_volume_claim" "kafka_data_pvc" {
  count = local.pv_disk_count

  metadata {
    name      = "data-0-kafka-cluster-kafka-${sum([count.index, local.pv_disk_count])}"
    namespace = local.kafkaNs
  }
  spec {
    access_modes = ["ReadWriteOnce"]
    resources {
      requests = {
        storage = "${data.google_compute_disk.kafka_data_pv[0].size}Gi"
      }
    }
    selector {
      match_labels = {
        target = "kafka-data"
      }
    }
    storage_class_name = ""
    volume_name        = kubernetes_persistent_volume.kafka_data_pv[count.index].metadata.0.name
  }
}


resource "kubernetes_persistent_volume" "kafka_controller_pv" {
  count = local.pv_disk_count
  metadata {
    name = "kafka-controller-${count.index}-pv"
    labels = {
      target = "kafka-controller"
    }
  }
  spec {
    capacity = {
      storage = data.google_compute_disk.kafka_controller_pv[count.index].size
    }
    access_modes = ["ReadWriteOnce"]
    claim_ref {
      namespace = local.kafkaNs
      name      = "data-0-kafka-cluster-controller-${count.index}"
    }
    persistent_volume_source {
      csi {
        driver        = "pd.csi.storage.gke.io"
        volume_handle = "projects/${var.Settings.gcpProject}/zones/${data.google_compute_disk.kafka_controller_pv[count.index].zone}/disks/kafka-controller-${count.index}"
      }
    }
    node_affinity {
      required {
        node_selector_term {
          match_expressions {
            key      = "topology.gke.io/zone"
            operator = "In"
            values   = [data.google_compute_disk.kafka_controller_pv[count.index].zone]
          }
        }
      }
    }
  }
}


resource "kubernetes_persistent_volume_claim" "kafka_controller_pvc" {
  count = local.pv_disk_count

  metadata {
    name      = "data-0-kafka-cluster-controller-${count.index}"
    namespace = local.kafkaNs
  }
  spec {
    access_modes = ["ReadWriteOnce"]
    resources {
      requests = {
        storage = "${data.google_compute_disk.kafka_controller_pv[0].size}Gi"
      }
    }
    selector {
      match_labels = {
        target = "kafka-controller"
      }
    }
    storage_class_name = ""
    volume_name        = kubernetes_persistent_volume.kafka_controller_pv[count.index].metadata.0.name
  }
}

