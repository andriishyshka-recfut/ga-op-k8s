
resource "kubernetes_deployment" "deployment_trac" {
  count = local.trac_setup
  metadata {
    name      = "trac-deployment"
    namespace = "trac"
    labels = {
      app = "trac"
    }
  }
  spec {
    replicas = 1
    selector {
      match_labels = {
        app = "trac"
      }
    }
    template {
      metadata {
        labels = {
          app = "trac"
        }
      }
      spec {
        container {
          name  = "trac"
          image = "harbor.regemini.io/trac/trac:1.4.3"
          port {
            container_port = "8123"
          }
        }
        image_pull_secrets {
          name = "harbor"
        }
      }
    }
  }
}

resource "kubernetes_service" "service_trac" {
  count = local.trac_setup
  metadata {
    name      = "trac"
    namespace = "trac"
  }
  spec {
    selector = {
      app = "trac"
    }
    port {
      port        = 8123
      target_port = 8123
    }
  }
}
