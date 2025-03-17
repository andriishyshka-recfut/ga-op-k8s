data "google_compute_disk" "tarantool_storage_pv" {
  count = local.tarantool_storage_count
  name    = "tarantool-vortex-storage-${element(range(local.tsc), floor(count.index / 2))}-${count.index % 2}"
  project = var.Settings.gcpProject
  zone = element([for i in range(local.tarantool_storage_count) : element(local.zones, i % 3)], count.index)
}


data "google_compute_disk" "tarantool_router_pv" {
  count = local.tarantool_router_count
  name    = "tarantool-vortex-router-${count.index}-0"
  project = var.Settings.gcpProject
  zone = element([for i in range(local.tarantool_router_count) : element(local.zones, i % 3)], count.index)
}

data "google_compute_disk" "tarantool_etcd_pv" {
  count = local.tarantool_etcd_count
  name    = "${local.tarantool_etcd_prefix}-${count.index}"
  project = var.Settings.gcpProject
  zone = element([for i in range(local.tarantool_etcd_count) : element(local.zones, i % 3)], count.index)
}





resource "kubernetes_persistent_volume" "tarantool_storage_pv" {
  count = local.tarantool_storage_count
  metadata {
    name = "${local.tarantool_storage_prefix}-${element(range(local.tsc), floor(count.index / 2))}-${count.index % 2}-pv"
    labels = {
      target = local.tarantool_storage_prefix
    }
  }
  spec {
    capacity = {
      storage = data.google_compute_disk.tarantool_storage_pv[count.index].size
    }
    access_modes = ["ReadWriteOnce"]
    claim_ref {
      namespace = local.namespace
      name = "tarantool-cartridge-data-volume-tarantool-cartridge-storage-${element(range(local.tsc), floor(count.index / 2))}-${count.index % 2}"
    }
    persistent_volume_source{
      csi {
        driver = "pd.csi.storage.gke.io"
        volume_handle = "projects/${var.Settings.gcpProject}/zones/${data.google_compute_disk.tarantool_storage_pv[count.index].zone}/disks/tarantool2-vortex-storage-${element(range(local.tsc), floor(count.index / 2))}-${count.index % 2}"
      }
    }
  node_affinity {
      required {
        node_selector_term {
          match_expressions {
            key = "topology.gke.io/zone"
            operator = "In"
            values = [ data.google_compute_disk.tarantool_storage_pv[count.index].zone]
          }
        }
      }
    }
  }
}



resource "kubernetes_persistent_volume" "tarantool_router_pv" {
  count = local.tarantool_router_count
  metadata {
    name = "${local.tarantool_router_prefix}-${count.index}-pv"
    labels = {
      target = local.tarantool_router_prefix
    }
  }
  spec {
    capacity = {
      storage = data.google_compute_disk.tarantool_router_pv[count.index].size
    }
    access_modes = ["ReadWriteOnce"]
    claim_ref {
      namespace = local.namespace
      name = "tarantool-cartridge-data-volume-tarantool-cartridge-router-${count.index}-0"
    }
    persistent_volume_source{
      csi {
        driver = "pd.csi.storage.gke.io"
        volume_handle = "projects/${var.Settings.gcpProject}/zones/${data.google_compute_disk.tarantool_router_pv[count.index].zone}/disks/tarantool2-vortex-router-${count.index}-0"
      }
    }
  node_affinity {
      required {
        node_selector_term {
          match_expressions {
            key = "topology.gke.io/zone"
            operator = "In"
            values = [data.google_compute_disk.tarantool_router_pv[count.index].zone]
          }
        }
      }
    }
  }
}




resource "kubernetes_persistent_volume" "tarantool_etcd_pv" {
  count = local.tarantool_etcd_count
  metadata {
    name = "${local.tarantool_etcd_prefix}-${count.index}-pv"
    labels = {
      target = local.tarantool_etcd_prefix
    }
  }
  spec {
    capacity = {
      storage = data.google_compute_disk.tarantool_etcd_pv[count.index].size
    }
    access_modes = ["ReadWriteOnce"]
    claim_ref {
      namespace = local.namespace
      name = "data-etcd-${count.index}"
    }
    persistent_volume_source{
      csi {
        driver = "pd.csi.storage.gke.io"
        volume_handle = "projects/${var.Settings.gcpProject}/zones/${data.google_compute_disk.tarantool_etcd_pv[count.index].zone}/disks/tarantool2-etcd-${count.index}"
      }
    }
  node_affinity {
      required {
        node_selector_term {
          match_expressions {
            key = "topology.gke.io/zone"
            operator = "In"
            values = [data.google_compute_disk.tarantool_etcd_pv[count.index].zone]
          }
        }
      }
    }
  }
}





resource "kubernetes_persistent_volume_claim" "tarantool_storage_pvc" {
    count = local.tarantool_storage_count

  metadata {
    name = "tarantool-cartridge-data-volume-tarantool-cartridge-storage-${element(range(local.tsc), floor(count.index / 2))}-${count.index % 2}"
    namespace = local.namespace
  }
  spec {
    access_modes = ["ReadWriteOnce"]
    resources {
      requests = {
        storage = "${data.google_compute_disk.tarantool_storage_pv[count.index].size}Gi"
      }
    }
    selector {
      match_labels = {
        target = local.tarantool_storage_prefix
      }
    }
    storage_class_name = ""
    volume_name = "${kubernetes_persistent_volume.tarantool_storage_pv[count.index].metadata.0.name}"
  }
}

resource "kubernetes_persistent_volume_claim" "tarantool_router_pvc" {
    count = local.tarantool_router_count

  metadata {
    name = "tarantool-cartridge-data-volume-tarantool-cartridge-router-${count.index}-0"
    namespace = local.namespace
  }
  spec {
    access_modes = ["ReadWriteOnce"]
    resources {
      requests = {
        storage = "${data.google_compute_disk.tarantool_router_pv[count.index].size}Gi"
      }
    }
    selector {
      match_labels = {
        target = local.tarantool_router_prefix
      }
    }
    storage_class_name = ""
    volume_name = "${kubernetes_persistent_volume.tarantool_router_pv[count.index].metadata.0.name}"
  }
}


resource "kubernetes_persistent_volume_claim" "tarantool_etcd_pvc" {
    count = local.tarantool_etcd_count

  metadata {
    name = "data-etcd-${count.index}"
    namespace = local.namespace
  }
  spec {
    access_modes = ["ReadWriteOnce"]
    resources {
      requests = {
        storage = "${data.google_compute_disk.tarantool_etcd_pv[count.index].size}Gi"
      }
    }
    selector {
      match_labels = {
        target = local.tarantool_etcd_prefix
      }
    }
    storage_class_name = ""
    volume_name = "${kubernetes_persistent_volume.tarantool_etcd_pv[count.index].metadata.0.name}"
  }
}

