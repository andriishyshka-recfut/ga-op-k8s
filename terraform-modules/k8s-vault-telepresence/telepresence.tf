resource "helm_release" "telepresence" {
  count      = var.Cluster == "production" ? 0 : 1
  name       = "traffic-manager"
  chart      = "telepresence-oss"
  repository = "oci://ghcr.io/telepresenceio"
  wait       = true
  atomic     = true
  namespace = "telepresence"
}
