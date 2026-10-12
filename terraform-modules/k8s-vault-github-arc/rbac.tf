resource "kubernetes_role" "buildx_github-runner" {
  metadata {
    name      = "buildx-github-runner"
    namespace = "github"
  }

  rule {
    api_groups = ["apps"]
    resources  = ["deployments"]
    verbs      = ["get", "list", "watch", "create", "update", "patch", "delete"]
  }

  rule {
    api_groups = [""]
    resources  = ["pods", "pods/log", "services", "configmaps"]
    verbs      = ["get", "list", "watch", "create", "update", "patch", "delete"]
  }
}

resource "kubernetes_role_binding" "buildx_github-runner" {
  metadata {
    name      = "buildx-github-runner"
    namespace = "github"
  }

  subject {
    kind      = "ServiceAccount"
    name      = "ga-github-runner-gha-rs-kube-mode"
    namespace = "github"
  }

  role_ref {
    api_group = "rbac.authorization.k8s.io"
    kind      = "Role"
    name      = kubernetes_role.buildx_github-runner.metadata[0].name
  }
}