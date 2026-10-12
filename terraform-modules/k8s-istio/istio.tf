data "vault_kv_secret_v2" "artifactory_creds" {
  mount = "secret"
  name  = "misc/artifactory/creds"
}
resource "kubernetes_namespace_v1" "istio_system" {
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
  name                 = "istio-base"
  chart                = "base"
  repository           = "oci://${var.RepositoryDomain}/ga-helm-virtual/istio/release/charts"
  version              = var.Settings.clusters[var.Cluster].versions.istio.helm_version
  wait                 = true
  atomic               = true
  namespace            = "istio-system"
  repository_username  = data.vault_kv_secret_v2.artifactory_creds.data["user"]
  repository_password  = data.vault_kv_secret_v2.artifactory_creds.data["password"]
  repository_cert_file = var.RepositoryDomain == "repo-external.recfut.com" ? "/tmp/artifactory-client.crt" : null
  repository_key_file  = var.RepositoryDomain == "repo-external.recfut.com" ? "/tmp/artifactory-client.key" : null

  depends_on = [
    kubernetes_namespace_v1.istio_system
  ]
}

resource "helm_release" "istiod" {
  name                 = "istiod"
  chart                = "istiod"
  repository           = "oci://${var.RepositoryDomain}/ga-helm-virtual/istio/release/charts"
  version              = var.Settings.clusters[var.Cluster].versions.istio.helm_version
  wait                 = true
  atomic               = true
  namespace            = "istio-system"
  repository_username  = data.vault_kv_secret_v2.artifactory_creds.data["user"]
  repository_password  = data.vault_kv_secret_v2.artifactory_creds.data["password"]
  repository_cert_file = var.RepositoryDomain == "repo-external.recfut.com" ? "/tmp/artifactory-client.crt" : null
  repository_key_file  = var.RepositoryDomain == "repo-external.recfut.com" ? "/tmp/artifactory-client.key" : null
  values               = [templatefile("${path.module}/templates/istiod.tftpl", {})]
  depends_on = [
    helm_release.istio_base
  ]
}

resource "helm_release" "istio_cni" {
  name                 = "istio-cni"
  chart                = "cni"
  repository           = "oci://${var.RepositoryDomain}/ga-helm-virtual/istio/release/charts"
  version              = var.Settings.clusters[var.Cluster].versions.istio.helm_version
  wait                 = true
  atomic               = true
  namespace            = "kube-system"
  repository_username  = data.vault_kv_secret_v2.artifactory_creds.data["user"]
  repository_password  = data.vault_kv_secret_v2.artifactory_creds.data["password"]
  repository_cert_file = var.RepositoryDomain == "repo-external.recfut.com" ? "/tmp/artifactory-client.crt" : null
  repository_key_file  = var.RepositoryDomain == "repo-external.recfut.com" ? "/tmp/artifactory-client.key" : null
  values               = [templatefile("${path.module}/templates/istio-cni.tftpl", {})]
  depends_on = [
    helm_release.istiod
  ]
}

resource "helm_release" "istio_ingress" {
  name                 = "istio-ingressgateway"
  chart                = "gateway"
  repository           = "oci://${var.RepositoryDomain}/ga-helm-virtual/istio/release/charts"
  version              = var.Settings.clusters[var.Cluster].versions.istio.helm_version
  wait                 = true
  atomic               = true
  namespace            = "istio-ingress"
  repository_username  = data.vault_kv_secret_v2.artifactory_creds.data["user"]
  repository_password  = data.vault_kv_secret_v2.artifactory_creds.data["password"]
  repository_cert_file = var.RepositoryDomain == "repo-external.recfut.com" ? "/tmp/artifactory-client.crt" : null
  repository_key_file  = var.RepositoryDomain == "repo-external.recfut.com" ? "/tmp/artifactory-client.key" : null
  values               = [templatefile("${path.module}/templates/ingress.tftpl", { ports = local.ports })]
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
