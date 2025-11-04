# #
# # resource "null_resource" "ansible_istio_playbook" {
# #   triggers = {
# #     //always_run = "${timestamp()}"
# #     // istio_version_change = var.Settings.clusters[var.Cluster].istio_version
# #     playbook_contents = md5(file("${path.module}/../../ansible/istio.yml"))
# #   }
# #   provisioner "local-exec" {
# #     command     = <<COMMAND
# #     cd  ${path.module}/../../ansible && \
# #     ansible-playbook istio.yml \
# #       -e 'ansible_python_interpreter=/usr/bin/python3'
# # COMMAND
# #     environment = local.ansibleEnvs
# #   }
# # }
resource "kubernetes_namespace" "istio_system" {
  metadata {
    name = "istio-system"
  }
}

resource "kubernetes_namespace" "istio_ingress" {
  count = local.notRed
  metadata {
    name = "istio-ingress"
    labels = {
      istio-injection = "enabled"
    }
  }
  depends_on = [
    helm_release.istiod
  ]
}


resource "helm_release" "istio_base" {
  name       = "istio-base"
  chart      = "base"
  repository = "https://istio-release.storage.googleapis.com/charts"
  version    = var.Settings.clusters[var.Cluster].versions.istio.helm_version
  wait       = true
  atomic     = true
  namespace  = "istio-system"

  depends_on = [
    kubernetes_namespace.istio_system
  ]
}

resource "helm_release" "istiod" {
  name       = "istiod"
  chart      = "istiod"
  repository = "https://istio-release.storage.googleapis.com/charts"
  version    = var.Settings.clusters[var.Cluster].versions.istio.helm_version
  wait       = true
  atomic     = true
  namespace  = "istio-system"
  values     = [templatefile("${path.module}/templates/istiod.tftpl", {})]
  depends_on = [
    helm_release.istio_base
  ]
}

resource "helm_release" "istio_cni" {
  name       = "istio-cni"
  chart      = "istio-cni"
  repository = "https://istio-release.storage.googleapis.com/charts"
  version    = var.Settings.clusters[var.Cluster].versions.istio.helm_version
  wait       = true
  atomic     = true
  namespace  = "kube-system"
  values     = [templatefile("${path.module}/templates/istio-cni.tftpl", {})]
  depends_on = [
    helm_release.istiod
  ]
}

resource "helm_release" "istio_ingress" {
  name       = "istio-ingressgateway"
  chart      = "gateway"
  repository = "https://istio-release.storage.googleapis.com/charts"
  version    = var.Settings.clusters[var.Cluster].versions.istio.helm_version
  wait       = true
  atomic     = true
  namespace  = "istio-ingress"
  values     = [templatefile("${path.module}/templates/ingress.tftpl", { ports = local.ports })]
  depends_on = [
    helm_release.istio_cni
  ]
}


resource "null_resource" "patch_istio_config" {
  triggers = {
    command = md5(local.command)
  }
  provisioner "local-exec" {
    interpreter = ["/bin/bash", "-c"]
    command     = local.command
  }
  depends_on = [helm_release.istiod]
}


resource "helm_release" "istio_telemetry" {
  name       = "istio-telemetry"
  chart      = "${path.module}/charts/telemetry"
  wait       = true
  atomic     = true
  namespace  = "istio-ingress"
  depends_on = [helm_release.istio_ingress]
}
