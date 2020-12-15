resource "helm_release" "cert-manager" {
  name       = "${var.Cluster}-cert-manager"
  repository = "https://charts.jetstack.io"
  chart      = "cert-manager"
  version    = var.Settings.clusters[var.Cluster][var.Color].cert_manager.version
  namespace  = "kube-system"
  set {
    name  = "installCRDs"
    value = "true"
  }
  # set {
  #   name  = "ingressShim.defaultIssuerName"
  #   value = "vault-issuer"
  # }
  # set {
  #   name  = "ingressShim.defaultIssuerKind"
  #   value = "ClusterIssuer"
  # }

  // Configure cert-manager to cleanup secrets on delete
  // https://github.com/jetstack/cert-manager/pull/819
  set {
    name  = "extraArgs[0]"
    value = "--enable-certificate-owner-ref=true"
  }
}


resource "null_resource" "ansible_cert-manager_letsencrypt_integration_playbook" {
  count = local.create_letsencrypt_issuers
  provisioner "local-exec" {
    command = <<COMMAND
    cd  ${path.module}/../../ansible && \
    ansible-playbook k8s-apply.yml \
      -e 'ansible_python_interpreter=/usr/bin/python3'
COMMAND
    environment = merge(local.ansible_envs, {
      k8s_apply_value = templatefile("${path.module}/cert-manager-issuer.tmpl", {})
    })

  }
  depends_on = [
    helm_release.cert-manager,
  ]
}
