
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

###################################
#    Features and capabilities
###################################


  set {
    name = "capabilities.continuousScan"
    value = "disable"
  }

  set {
    name = "capabilities.prometheusExporter"
    value = "enable"
  }

  set {
    name = "kubescape.prometheusAnnotation.enabled"
    value = "true"
  }

  set {
    name = "capabilities.nodeScan"
    value = "disable"
  }

  set {
    name = "capabilities.relevancy"
    value = "disable"
  }

  set {
    name = "capabilities.vulnerabilityScan"
    value = "disable"
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
    name  = "kubescape.serviceMonitor.enabled"
    value = "true"
  }

  set {
    name  = "kubescape.enableHostScan"
    value = "false"
  }


###################################
#    Settings
###################################

  set {
    name  = "kubescapeScheduler.scanSchedule"
    value = "0 2 * * *"
  }

  set {
    name  = "kubescape.resources.requests.cpu"
    value = "600m"
  }

  set {
    name  = "kubescape.resources.requests.memory"
    value = "1Gi"
  }
  # set {
  #   name  = "kubescape.resources.limits.cpu"
  #   value = "1000m"
  # }
  # set {
  #   name  = "kubescape.resources.limits.memory"
  #   value = "1Gi"
  # }

  set {
    name  = "cloudProviderEngine"
    value = "gke"
  }
  set {
    name  = "clusterName"
    value = local.clusterName
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
    name  = "kubescape.serviceMonitor.namespace"
    value = "monitoring"
  }

  set {
    name  = "prometheusExporter.name"
    value = "prometheus-kubescape"
  }

  timeout = 60

  depends_on = [kubernetes_secret.minio_credentials]
}

