terraform {
  required_providers {
    kubectl = {
      source  = "registry.opentofu.org/gavinbunney/kubectl"
      version = ">= 1.10.0"
    }
  }
}

resource "kubernetes_manifest" "git_repositories" {
  for_each = local.git-repositories
  manifest = yamldecode(templatefile("${path.module}/templates/git-repository.yaml.tftpl", { values = each.value, name = each.key, globals = local.globals }))
}

resource "kubernetes_manifest" "helm_repositories" {
  for_each = local.helm-repositories
  manifest = yamldecode(templatefile("${path.module}/templates/helm-repository.yaml.tftpl", { values = each.value, name = each.key, globals = local.globals }))
}

resource "kubernetes_manifest" "helm_releases" {
  for_each   = local.helm-releases
  manifest   = yamldecode(templatefile("${path.module}/templates/helm-release.yaml.tftpl", { values = each.value, name = each.key, globals = local.globals }))
  depends_on = [kubernetes_manifest.helm_repositories]
}

resource "kubernetes_manifest" "kustomizations" {
  for_each   = local.kustomizations
  manifest   = yamldecode(templatefile("${path.module}/templates/kustomization.yaml.tftpl", { values = each.value, name = each.key, globals = local.globals }))
  depends_on = [kubernetes_manifest.git_repositories]
}

resource "kubernetes_manifest" "notification-providers" {
  for_each = local.notification-providers
  manifest = yamldecode(templatefile("${path.module}/templates/notification-provider.yaml.tftpl", { values = each.value, name = each.key, globals = local.globals }))
}

resource "kubernetes_manifest" "alerts" {
  for_each   = local.alerts
  manifest   = yamldecode(templatefile("${path.module}/templates/alert.yaml.tftpl", { values = each.value, name = each.key, globals = local.globals }))
  depends_on = [kubernetes_manifest.notification-providers]
}


# resource "local_file" "alert" {
#   for_each = local.alerts
#   content  = templatefile("${path.module}/templates/alert.yaml.tftpl", { values = each.value, name = each.key, globals = local.globals })
#   filename = "${path.module}/alert.yaml"
# }
