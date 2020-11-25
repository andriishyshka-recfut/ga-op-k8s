
resource "kubernetes_config_map" "policy" {
  metadata {
    name      = "policy"
    namespace = local.minio-ns
  }
  data = {
    policy_json = file("minio-policy.json")
  }
}

resource "kubernetes_job" "add-policy" {

  metadata {
    name      = "add-policy"
    namespace = local.minio-ns
  }
  spec {
    template {
      metadata {}
      spec {
        container {
          name    = "mc"
          image   = "minio/mc"
          command = ["mc", "admin", "policy", "add", "minio", "geminiadvisory.io", "/tmp/policy_json"]
          env {
            name = "accesskey"
            value_from {
              secret_key_ref {
                name = "minio-credentials"
                key  = "accesskey"
              }
            }
          }
          env {
            name = "secretkey"
            value_from {
              secret_key_ref {
                name = "minio-credentials"
                key  = "secretkey"
              }
            }
          }
          env {
            name  = "MC_HOST_minio"
            value = "http://$(accesskey):$(secretkey)@minio:9000"
          }
          volume_mount {
            mount_path = "/tmp/"
            name       = "policy"
          }

        }
        volume {
          name = "policy"
          config_map {
            #key  = "policy_json"
            name = "policy"
          }
        }
        restart_policy = "Never"
      }
    }
    backoff_limit = 4
  }
  wait_for_completion = true
  depends_on = [
    helm_release.minio,
    kubernetes_config_map.policy
  ]
}
