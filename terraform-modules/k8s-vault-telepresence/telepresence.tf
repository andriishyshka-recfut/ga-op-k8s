resource "helm_release" "telepresence" {
  name       = "traffic-manager"
  chart      = "telepresence-oss"
  repository = "oci://ghcr.io/telepresenceio"
  wait       = true
  atomic     = true
  namespace = "telepresence"
}
