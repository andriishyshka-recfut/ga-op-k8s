#
# resource "null_resource" "ansible_istio_playbook" {
#   triggers = {
#     //always_run = "${timestamp()}"
#     // istio_version_change = var.Settings.clusters[var.Cluster].istio_version
#     playbook_contents = md5(file("${path.module}/../../ansible/istio.yml"))
#   }
#   provisioner "local-exec" {
#     command     = <<COMMAND
#     cd  ${path.module}/../../ansible && \
#     ansible-playbook istio.yml \
#       -e 'ansible_python_interpreter=/usr/bin/python3'
# COMMAND
#     environment = local.ansibleEnvs
#   }
# }
resource "kubernetes_namespace" "istio_system" {
  metadata {
    name = "istio-system"
  }
}

resource "kubernetes_namespace" "istio_ingress" {
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
  wait       = true
  atomic     = true
  namespace  = "istio-system"
  depends_on = [
    helm_release.istio_base
  ]
}

resource "helm_release" "istio_ingress" {
  name       = "istio-ingressgateway"
  chart      = "gateway"
  repository = "https://istio-release.storage.googleapis.com/charts"
  wait       = true
  atomic     = true
  namespace  = "istio-ingress"
  set {
    name  = "service.type"
    value = "NodePort"
  }
  set {
    name  = "autoscaling.minReplicas"
    value = 2
  }
  depends_on = [
    kubernetes_namespace.istio_ingress
  ]
}

resource "helm_release" "istio_ingress_lb" {
  name       = "istio-ingressgateway-lb"
  chart      = "gateway"
  repository = "https://istio-release.storage.googleapis.com/charts"
  wait       = true
  atomic     = true
  namespace  = "istio-ingress"
  set {
    name  = "service.type"
    value = "LoadBalancer"
  }
  set {
    name  = "autoscaling.minReplicas"
    value = 2
  }
  set {
    name  = "service.loadBalancerIP"
    value = var.Settings.clusters[var.Cluster].load_balancer_ip
  }
  set {
    name  = "service.externalTrafficPolicy"
    value = "Local"
  }
  depends_on = [
    kubernetes_namespace.istio_ingress
  ]
}
