resource "kubectl_manifest" "git_repositories" {
  for_each  = local.git-repositories
  yaml_body = templatefile("${path.module}/templates/git-repository.yaml.tftpl", { values = each.value, name = each.key, globals = local.globals })
}

resource "kubectl_manifest" "helm_repositories" {
  for_each  = local.helm-repositories
  yaml_body = templatefile("${path.module}/templates/helm-repository.yaml.tftpl", { values = each.value, name = each.key, globals = local.globals })
}

resource "kubectl_manifest" "helm_releases" {
  for_each   = local.helm-releases
  yaml_body  = templatefile("${path.module}/templates/helm-release.yaml.tftpl", { values = each.value, name = each.key, globals = local.globals })
  depends_on = [kubectl_manifest.helm_repositories]
}

resource "kubectl_manifest" "kustomizations" {
  for_each   = local.kustomizations
  yaml_body  = templatefile("${path.module}/templates/kustomization.yaml.tftpl", { values = each.value, name = each.key, globals = local.globals })
  depends_on = [kubectl_manifest.git_repositories]
}

resource "kubectl_manifest" "notification-providers" {
  for_each  = local.notification-providers
  yaml_body = templatefile("${path.module}/templates/notification-provider.yaml.tftpl", { values = each.value, name = each.key, globals = local.globals })
}

resource "kubectl_manifest" "alerts" {
  for_each   = local.alerts
  yaml_body  = templatefile("${path.module}/templates/alert.yaml.tftpl", { values = each.value, name = each.key, globals = local.globals })
  depends_on = [kubectl_manifest.notification-providers]
}

# resource "kubernetes_manifest" "git_repositories" {
#   for_each = local.git-repositories
#   manifest = yamldecode(templatefile("${path.module}/templates/git-repository.yaml.tftpl", { values = each.value, name = each.key, globals = local.globals }))
# }



# resource "kubernetes_manifest" "helm_repositories" {
#   for_each = local.helm-repositories
#   manifest = yamldecode(templatefile("${path.module}/templates/helm-repository.yaml.tftpl", { values = each.value, name = each.key, globals = local.globals }))
# }

# resource "kubernetes_manifest" "helm_releases" {
#   for_each   = local.helm-releases
#   manifest   = yamldecode(templatefile("${path.module}/templates/helm-release.yaml.tftpl", { values = each.value, name = each.key, globals = local.globals }))
#   depends_on = [kubernetes_manifest.helm_repositories]
# }

# resource "kubernetes_manifest" "kustomizations" {
#   for_each   = local.kustomizations
#   manifest   = yamldecode(templatefile("${path.module}/templates/kustomization.yaml.tftpl", { values = each.value, name = each.key, globals = local.globals }))
#   depends_on = [kubernetes_manifest.git_repositories]
# }

# resource "kubernetes_manifest" "notification-providers" {
#   for_each = local.notification-providers
#   manifest = yamldecode(templatefile("${path.module}/templates/notification-provider.yaml.tftpl", { values = each.value, name = each.key, globals = local.globals }))
# }

# resource "kubernetes_manifest" "alerts" {
#   for_each   = local.alerts
#   manifest   = yamldecode(templatefile("${path.module}/templates/alert.yaml.tftpl", { values = each.value, name = each.key, globals = local.globals }))
#   depends_on = [kubernetes_manifest.notification-providers]
# }


# resource "local_file" "alert" {
#   for_each = local.alerts
#   content  = templatefile("${path.module}/templates/alert.yaml.tftpl", { values = each.value, name = each.key, globals = local.globals })
#   filename = "${path.module}/alert.yaml"
# }
