resource "helm_release" "cert_manager" {
  name       = "${var.Cluster}-cert-manager"
  repository = "https://charts.jetstack.io"
  chart      = "cert-manager"
  version    = var.Settings.clusters[var.Cluster].versions.cert_manager.version
  namespace  = "kube-system"
  set = [
    {
      name  = "installCRDs"
      value = "true"
    },
    {
      name  = "extraArgs[0]"
      value = "--enable-certificate-owner-ref=true"
    }
  ]
}

resource "null_resource" "kubectl_letsencrypt_issuers" {
  triggers = {
    manifest_hash = sha256(local.cert_manager_issuers)
  }
  provisioner "local-exec" {
    interpreter = ["/bin/bash", "-c"]
    environment = {
      ISSUERS_YAML = local.cert_manager_issuers
    }
    command = <<COMMAND
    printf '%s\n' "$ISSUERS_YAML" |\
    kubectl apply --server ${local.gkeClusterEndpoint}  \
     --token ${local.gkeBearerToken}  --insecure-skip-tls-verify=true \
     -f -
COMMAND
  }
  depends_on = [
    helm_release.cert_manager,
  ]
}
