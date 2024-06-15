data "google_compute_disk" "kafka_data_pv" {
  count = local.pv_disk_count
  name    = "kafka-data-${count.index}"
  project = var.Settings.gcpProject
  zone = element([for i in range(local.pv_disk_count) : element(local.zones, i % 3)], count.index)
}

data "google_compute_disk" "kafka_zookeeper_pv" {
  count = local.pv_disk_count
  name    = "kafka-zookeeper-${count.index}"
  project = var.Settings.gcpProject
  zone = element([for i in range(local.pv_disk_count) : element(local.zones, i % 3)], count.index)
}

data "google_compute_disk" "kafka_controller_pv" {
  count = local.pv_disk_count
  name    = "kafka-controller-${count.index}"
  project = var.Settings.gcpProject
  zone = element([for i in range(local.pv_disk_count) : element(local.zones, i % 3)], count.index)
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
      name = "data-0-kafka-cluster-kafka-${count.index}"
    }
    persistent_volume_source{
      csi {
        driver = "pd.csi.storage.gke.io"
        volume_handle = "projects/${var.Settings.gcpProject}/zones/${data.google_compute_disk.kafka_data_pv[count.index].zone}/disks/kafka-data-${count.index}"
      }
    }
  node_affinity {
      required {
        node_selector_term {
          match_expressions {
            key = "topology.gke.io/zone"
            operator = "In"
            values = [ data.google_compute_disk.kafka_data_pv[count.index].zone]
          }
        }
      }
    }
  }
}



resource "kubernetes_persistent_volume" "kafka_zookeeper_pv" {
  count = local.pv_disk_count
  metadata {
    name = "kafka-zookeeper-${count.index}-pv"
    labels = {
      target = "kafka-zookeeper"
    }
  }
  spec {
    capacity = {
      storage = data.google_compute_disk.kafka_zookeeper_pv[count.index].size
    }
    access_modes = ["ReadWriteOnce"]
    claim_ref {
      namespace = local.kafkaNs
      name = "data-kafka-cluster-zookeeper-${count.index}"
    }
    persistent_volume_source{
      csi {
        driver = "pd.csi.storage.gke.io"
        volume_handle = "projects/${var.Settings.gcpProject}/zones/${data.google_compute_disk.kafka_zookeeper_pv[count.index].zone}/disks/kafka-zookeeper-${count.index}"
      }
    }
  node_affinity {
      required {
        node_selector_term {
          match_expressions {
            key = "topology.gke.io/zone"
            operator = "In"
            values = [data.google_compute_disk.kafka_zookeeper_pv[count.index].zone]
          }
        }
      }
    }
  }
}




resource "kubernetes_persistent_volume_claim" "kafka_data_pvc" {
    count = local.pv_disk_count

  metadata {
    name = "data-0-kafka-cluster-kafka-${count.index}"
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
    volume_name = "${kubernetes_persistent_volume.kafka_data_pv[count.index].metadata.0.name}"
  }
}

resource "kubernetes_persistent_volume_claim" "kafka_zookeeper_pvc" {
    count = local.pv_disk_count

  metadata {
    name = "data-kafka-cluster-zookeeper-${count.index}"
    namespace = local.kafkaNs
  }
  spec {
    access_modes = ["ReadWriteOnce"]
    resources {
      requests = {
        storage = "${data.google_compute_disk.kafka_zookeeper_pv[0].size}Gi"
      }
    }
    selector {
      match_labels = {
        target = "kafka-zookeeper"
      }
    }
    storage_class_name = ""
    volume_name = "${kubernetes_persistent_volume.kafka_zookeeper_pv[count.index].metadata.0.name}"
  }
}






resource "kubernetes_persistent_volume" "kafka_controller_pv" {
  count = local.pv_disk_count
  metadata {
    name = "kafka-controller-${sum([count.index,3])}-pv"
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
      name = "data-0-kafka-cluster-controller-${sum([count.index,3])}"
    }
    persistent_volume_source{
      csi {
        driver = "pd.csi.storage.gke.io"
        volume_handle = "projects/${var.Settings.gcpProject}/zones/${data.google_compute_disk.kafka_controller_pv[count.index].zone}/disks/kafka-controller-${count.index}"
      }
    }
  node_affinity {
      required {
        node_selector_term {
          match_expressions {
            key = "topology.gke.io/zone"
            operator = "In"
            values = [data.google_compute_disk.kafka_controller_pv[count.index].zone]
          }
        }
      }
    }
  }
}





resource "kubernetes_persistent_volume_claim" "kafka_controller_pvc" {
    count = local.pv_disk_count

  metadata {
    name = "data-0-kafka-cluster-controller-${sum([count.index,3])}"
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
        target = "kafka-controller-x"
      }
    }
    storage_class_name = ""
    volume_name = "${kubernetes_persistent_volume.kafka_controller_pv[count.index].metadata.0.name}"
  }
}

