
data "vault_generic_secret" "minio_credentials" {
  path = "secret/minio/users"
}


locals {
  accessKey               = jsondecode(data.vault_generic_secret.minio_credentials.data["kubescape"]).accessKey
  secretKey               = jsondecode(data.vault_generic_secret.minio_credentials.data["kubescape"]).secretKey
}


resource "kubernetes_secret" "minio_credentials" {
  metadata {
    name      = "minio-credentials"
    namespace = "kubescape"
  }

  data = {
    "accesskey" = local.accessKey
    "secretkey" = local.secretKey
  }
}


resource "helm_release" "kubescape" {
  name              = "kubescape"
  repository        = "${path.module}"
  chart             = "kubescape-operator"
  wait              = true
  atomic            = true
  namespace         = "kubescape"

  set {
    name = "kubescape.image.tag"
    value = "v3.0.3"
  }

  set {
    name = "kubescapeScheduler.image.tag"
    value = "v0.2.2"
  }

  set {
    name = "capabilities.continuousScan"
    value = "disabled"
  }

  set {
    name = "capabilities.nodeScan"
    value = "disabled"
  }

  set {
    name = "capabilities.relevancy"
    value = "disabled"
  }

  set {
    name = "capabilities.vulnerabilityScan"
    value = "disabled"
  }

  set {
    name  = "cloudProviderEngine"
    value = "gke"
  }
  set {
    name  = "clusterName"
    value = local.clusterName
  }
  set {
    name  = "kubescapeScheduler.scanSchedule"
    value = "0 2 * * *"
  }
  set {
    name  = "kubescapeScheduler.enabled"
    value = "true"
  }

  set {
    name  = "kubescape.enabled"
    value = "true"
  }
  set {
    name  = "kubescape.submit"
    value = "false"
  }
  set {
    name  = "kubescape.minioBucket"
    value = local.minioBucket
  }
  set {
    name  = "kubescape.skipUpdateCheck"
    value = "true"
  }
  set {
    name  = "kubescape.enableHostScan"
    value = "false"
  }
  set {
    name = "kubescape.resources.limits.cpu"
    value = "250m"
  }
  set {
    name = "kubescape.resources.requests.memory"
    value = "2Gi"
  }
  set {
    name = "kubescape.resources.limits.memory"
    value = "3Gi"
  }

  set {
    name  = "kubescape.serviceMonitor.enabled"
    value = "true"
  }

  set {
    name  = "kubescape.serviceMonitor.namespace"
    value = "monitoring"
  }

  timeout = 60

  depends_on = [kubernetes_secret.minio_credentials]
}

