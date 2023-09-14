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
  set {
    name  = "global.logAsJson"
    value = true
  }
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
  dynamic "set" {
    for_each = local.ports
    content {
      name  = "service.ports[${set.key}].name"
      value = set.value["name"]
    }
  }
  dynamic "set" {
    for_each = local.ports
    content {
      name  = "service.ports[${set.key}].protocol"
      value = set.value["protocol"]
    }
  }
  dynamic "set" {
    for_each = local.ports
    content {
      name  = "service.ports[${set.key}].port"
      value = set.value["port"]
    }
  }
  dynamic "set" {
    for_each = local.ports
    content {
      name  = "service.ports[${set.key}].targetPort"
      value = set.value["port"]
    }
  }
  dynamic "set" {
    for_each = local.ports
    content {
      name  = "service.ports[${set.key}].nodePort"
      value = set.value["nodePort"]
    }
  }
  depends_on = [
    helm_release.istiod
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

resource "kubernetes_manifest" "telemetry_istio_ingress_audit_logs" {
  manifest = {
    "apiVersion" = "telemetry.istio.io/v1alpha1"
    "kind"       = "Telemetry"
    "metadata" = {
      "name"      = "audit-logs"
      "namespace" = "istio-ingress"
    }
    "spec" = {
      "accessLogging" = [
        {
          "providers" = [
            {
              "name" = "envoy"
            },
          ]
        },
      ]
    }
  }
  depends_on = [helm_release.istiod]
}
