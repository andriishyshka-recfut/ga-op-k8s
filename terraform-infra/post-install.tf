// Upload temp key to be able run ansible

data "external" "data" {
  program = ["sh", "../data.sh"]
}

data "google_client_openid_userinfo" "me" {
}

data "google_client_config" "default" {
}


resource "google_os_login_ssh_public_key" "cache" {
  user =  data.google_client_openid_userinfo.me.email
  key = data.external.data.result["pub_certificate"]
  expiration_time_usec = data.external.data.result["expiration_date"]
}

output "expiration_date" {
  value = data.external.data.result["expiration_date"]
}
output "pub_certificate" {
  value = data.external.data.result["pub_certificate"]
}

resource "null_resource" "ansible_playbook" {

  triggers = {
    always_run = "${timestamp()}"
  }

  provisioner "local-exec" {
    command = "cd ansible && ansible-playbook playbook.yml --user  sa_$(jq .client_id $GOOGLE_CREDENTIALS -j) --private-key ../ssh-key-ansible-sa"
    environment = {
    CLUSTER_SETTINGS = jsonencode(module.common-vars.cluster_settings)
    CLUSTER = var.cluster
    ANSIBLE_STDOUT_CALLBACK = "debug"
    HOST  = "https://${google_container_cluster.infra.endpoint}"
    API_KEY = data.google_client_config.default.access_token
    CLUSTER_CA_CERTIFICATE = base64decode(google_container_cluster.infra.master_auth[0].cluster_ca_certificate,)
    }
  }
  depends_on = [
    google_container_node_pool.infra_preemptible_nodes
  ]
}



resource "helm_release" "cert-manager" {
  name       = "cert-manager"
  repository = "https://charts.jetstack.io"
  chart      = "cert-manager"
  version    = "v0.15.0"
  namespace  = "kube-system"
  set {
    name = "installCRDs"
    value = "true"
  }
  depends_on = [
    google_container_node_pool.infra_preemptible_nodes
  ]
}
