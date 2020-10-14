resource "helm_release" "cert-manager" {
  name       = "${var.cluster}-cert-manager"
  repository = "https://charts.jetstack.io"
  chart      = "cert-manager"
  version    = var.settings.clusters[var.cluster][var.color].cert_manager.version
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

#
# data "kubernetes_service_account" "cert-manager" {
#   metadata {
#     name      = "${var.cluster}-cert-manager"
#     namespace = "kube-system"
#   }
#   depends_on = [
#     helm_release.cert-manager
#   ]
# }

resource "null_resource" "ansible_cert-manager_vault_integration_playbook" {

  provisioner "local-exec" {
    command = <<COMMAND
    cd  ${path.module}/../../ansible && \
    ansible-playbook k8s-apply.yml \
      -e 'ansible_python_interpreter=/usr/bin/python3'
COMMAND
    environment = {
      CLUSTER_SETTINGS        = jsonencode(var.settings)
      CLUSTER                 = var.cluster
      ANSIBLE_STDOUT_CALLBACK = "debug"
      HOST                    = local.gke_cluster_endpoint
      API_KEY                 = local.gke_bearer_token
      CLUSTER_CA_CERTIFICATE  = local.cluster_ca_certificate
      k8s_apply_value         = templatefile("${path.module}/cert-manager-issuer.tmpl", {})
    }
  }
  depends_on = [
    helm_release.cert-manager,
  ]
}
