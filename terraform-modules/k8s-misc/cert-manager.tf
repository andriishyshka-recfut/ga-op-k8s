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
    # playbook_contents  = md5(file("${path.module}/certificates.yaml.tmpl"))
  }
  provisioner "local-exec" {
    interpreter = ["/bin/bash", "-c"]
    command     = <<COMMAND
    kubectl apply --server ${local.gkeClusterEndpoint}  \
     --token ${local.gkeBearerToken}  --insecure-skip-tls-verify=true \
     -f ${path.module}/cert-manager-issuers.yaml
COMMAND
  }
  depends_on = [
    helm_release.cert_manager,
  ]
}
