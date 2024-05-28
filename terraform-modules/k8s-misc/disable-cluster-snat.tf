resource "kubernetes_config_map" "ipmasq" {
  metadata {
    name      = "ip-masq-agent"
    namespace = "kube-system"
  }

  data = {
    "config" = "${file("${path.module}/ip-masq-cm.yml")}"
  }

}
