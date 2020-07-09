resource "helm_release" "cert-manager" {
  name       = "${var.cluster}-cert-manager"
  repository = "https://charts.jetstack.io"
  chart      = "cert-manager"
  version    = var.settings.cluster_settings[var.cluster].cert_manager_version
  namespace  = "kube-system"
  set {
    name  = "installCRDs"
    value = "true"
  }
  set {
    name  = "ingressShim.defaultIssuerName"
    value = "vault-issuer"
  }
  set {
    name  = "ingressShim.defaultIssuerKind"
    value = "ClusterIssuer"
  }

  // Configure cert-manager to cleanup secrets on delete
  // https://github.com/jetstack/cert-manager/pull/819
  set {
    name  = "extraArgs[0]"
    value = "--enable-certificate-owner-ref=true"
  }
  depends_on = [
    google_container_node_pool.cluster_preemptible_nodes
  ]
}


data "kubernetes_service_account" "cert-manager" {
  metadata {
    name      = "${var.cluster}-cert-manager"
    namespace = "kube-system"
  }
  depends_on = [
    helm_release.cert-manager
  ]
}

resource "null_resource" "ansible_cert-manager_playbook" {
  triggers = {
    //always_run = "${timestamp()}"
    // istio_version_change = var.settings.cluster_settings[var.cluster].istio_version
    gke_cluster_change = google_container_cluster.cluster.id
    playbook_contents  = md5(file("${path.module}/certificates.yaml.tmpl"))
  }
  provisioner "local-exec" {
    command = <<COMMAND
    cd  ${path.module}/../../ansible && \
    ansible-playbook k8s-apply.yml \
      -e 'ansible_python_interpreter=/usr/bin/python3'
COMMAND
    environment = {
      CLUSTER_SETTINGS        = jsonencode(var.settings.cluster_settings)
      CLUSTER                 = var.cluster
      ANSIBLE_STDOUT_CALLBACK = "debug"
      HOST                    = "https://${google_container_cluster.cluster.endpoint}"
      API_KEY                 = data.google_client_config.default.access_token
      CLUSTER_CA_CERTIFICATE  = base64decode(google_container_cluster.cluster.master_auth[0].cluster_ca_certificate, )
      k8s_apply_value         = templatefile("${path.module}/certificates.yaml.tmpl", { default_secret_name = data.kubernetes_service_account.cert-manager.default_secret_name })
    }
  }
  depends_on = [
    google_container_node_pool.cluster_preemptible_nodes,
    helm_release.cert-manager,
    null_resource.ansible_vault_k8s_auth
  ]
}
