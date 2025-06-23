resource "kubernetes_config_map" "reboot_date" {
  metadata {
    name      = "reboot-date"
    namespace = local.globalSettings.namespace
  }
  data = {
    reboot_date = "20250621"
  }
}
