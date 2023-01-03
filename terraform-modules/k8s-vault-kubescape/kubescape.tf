resource "helm_release" "kubescape" {
  name              = "kubescape"
  repository        = "https://kubescape.github.io/helm-charts/"
  chart             = "kubescape-cloud-operator"
  wait              = true
  atomic            = true
  namespace         = "kubescape"

  set {
    name  = "cloudProviderEngine"
    value = "gke"
  }
  set {
    name  = "clusterName"
    value = local.clusterName
  }
  set {
    name  = "kubescape.submit"
    value = "false"
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


}

