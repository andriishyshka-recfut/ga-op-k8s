data "vault_generic_secret" "harbor_token" {
  path = "secret/goharbor/docker_login"
}

resource "kubernetes_persistent_volume" "nfs" {
  metadata {
    name = "nfs-pv"
  }
  spec {
    capacity = {
      storage = local.volume_size
    }
    access_modes = ["ReadWriteMany"]
    persistent_volume_source {
      nfs {
        server = "nfs-server.nfs.svc.cluster.local"
        path   = "/cvat"
      }
    }
  }
}

resource "kubernetes_manifest" "persistentvolumeclaim_nfs" {
  depends_on = [kubernetes_persistent_volume.nfs]
  manifest   = yamldecode(templatefile("${path.module}/pvc.yaml.tftpl", { storage = local.volume_size }))
}

resource "helm_release" "cvat" {
  name                = "cvat"
  namespace           = local.namespace
  chart               = "oci://harbor.regemini.io/helm/cvat"
  wait                = true
  atomic              = true
  version             = "0.15.1"
  timeout             = 900
  repository_username = data.vault_generic_secret.harbor_token.data.user
  repository_password = data.vault_generic_secret.harbor_token.data.password
  values = [
    templatefile("${path.module}/values-main.yaml.tftpl", { tag = "v2.44.1" }),
    templatefile("${path.module}/values-affinity.yaml.tftpl", { affinity_list = local.affinity_list }),
    templatefile("${path.module}/values-volumes.yaml.tftpl", { volumes_list = local.pvc_list })
  ]

  depends_on = [kubernetes_manifest.persistentvolumeclaim_nfs]
}
