# data "google_compute_disk" "grafana_pv" {
#   name    = "grafana-clients-red"
#   project = "orbital-wording-233917"
#   zone = "us-east4-b"
# }




# resource "kubernetes_persistent_volume" "grafana_pv" {
#   metadata {
#     name = "grafana-clients-red-pv"
#     labels = {
#       target = "grafana-clients"
#     }
#   }
#   spec {
#     capacity = {
#       storage = data.google_compute_disk.grafana_pv.size
#     }
#     access_modes = ["ReadWriteOnce"]
#     claim_ref {
#       namespace = local.grafanaNs
#       name = "grafana-clients-pvc"
#     }
#     persistent_volume_source{
#       csi {
#         driver = "pd.csi.storage.gke.io"
#         volume_handle = "projects/orbital-wording-233917/zones/us-east4-b/disks/grafana-clients-red"
#       }
#     }
#   node_affinity {
#       required {
#         node_selector_term {
#           match_expressions {
#             key = "topology.gke.io/zone"
#             operator = "In"
#             values = [ "us-east4-b" ]
#           }
#         }
#       }
#     }
#   }
# }




# resource "kubernetes_persistent_volume_claim" "grafana_pvc" {

#   metadata {
#     name = "grafana-clients-pvc"
#     namespace = local.grafanaNs
#   }
#   spec {
#     access_modes = ["ReadWriteOnce"]
#     resources {
#       requests = {
#         storage = "${data.google_compute_disk.grafana_pv.size}Gi"
#       }
#     }
#     selector {
#       match_labels = {
#         target = "grafana-clients"
#       }
#     }
#     storage_class_name = ""
#     volume_name = "${kubernetes_persistent_volume.grafana_pv.metadata.0.name}"
#   }
# }

