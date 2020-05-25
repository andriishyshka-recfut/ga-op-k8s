// Upload temp key to be able run ansible

data "external" "data" {
  program = ["sh", "../data.sh"]
}

data "google_client_openid_userinfo" "me" {
}
data "google_service_account" "me" {
  account_id = element(split("@",data.google_client_openid_userinfo.me.email),0)
}
data "google_client_config" "default" {
}


resource "google_os_login_ssh_public_key" "cache" {
  user =  data.google_client_openid_userinfo.me.email
  key = data.external.data.result["pub_certificate"]
  expiration_time_usec = data.external.data.result["expiration_date"]
}

#output "expiration_date" {
  #value = data.external.data.result["expiration_date"]
#}
#output "pub_certificate" {
  #value = data.external.data.result["pub_certificate"]
#}



resource "helm_release" "cert-manager" {
  name       = "cert-manager"
  repository = "https://charts.jetstack.io"
  chart      = "cert-manager"
  version    = var.settings.cluster_settings[var.cluster].cert_manager_version
  namespace  = "kube-system"
  set {
    name = "installCRDs"
    value = "true"
  }
  depends_on = [
    google_container_node_pool.infra_preemptible_nodes
  ]
}

resource "null_resource" "ansible_istio_playbook" {
  triggers = {
    //always_run = "${timestamp()}"
    // istio_version_change = var.settings.cluster_settings[var.cluster].istio_version
    gke_cluster_change = google_container_cluster.infra.id
  }
  provisioner "local-exec" {
    command = "cd  ${path.root}/../ansible && ansible-playbook istio.yml --user   sa_${data.google_service_account.me.unique_id} -e 'ansible_python_interpreter=/usr/bin/python3.7'"
    environment = {
    CLUSTER_SETTINGS = jsonencode(var.settings.cluster_settings)
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

resource "null_resource" "ansible_bastion_playbook" {
  triggers = {
    //always_run = "${timestamp()}"
    istio_change = null_resource.ansible_istio_playbook.id
    gke_cluster_change = google_container_cluster.infra.id
  }
  provisioner "local-exec" {
    command = "cd  ${path.root}/../ansible && ansible-playbook bastion.yml --user  sa_${data.google_service_account.me.unique_id} -e 'ansible_python_interpreter=/usr/bin/python3.7' "
    environment = {
    CLUSTER_SETTINGS = jsonencode(var.settings.cluster_settings)
    CLUSTER = var.cluster
    ANSIBLE_STDOUT_CALLBACK = "debug"
    HOST  = "https://${google_container_cluster.infra.endpoint}"
    API_KEY = data.google_client_config.default.access_token
    CLUSTER_CA_CERTIFICATE = base64decode(google_container_cluster.infra.master_auth[0].cluster_ca_certificate,)
    }
  }
  depends_on = [
    google_container_node_pool.infra_preemptible_nodes,
    null_resource.ansible_istio_playbook
  ]
}

resource "null_resource" "ansible_post_install_verification_playbook" {
  triggers = {
    always_run = "${timestamp()}"
  }
  provisioner "local-exec" {
    command = "cd ${path.root}/../ansible && ansible-playbook test-workload.yml --user  sa_${data.google_service_account.me.unique_id} -e 'ansible_python_interpreter=/usr/bin/python3.7' "
    environment = {
    CLUSTER_SETTINGS = jsonencode(var.settings.cluster_settings)
    CLUSTER = var.cluster
    ANSIBLE_STDOUT_CALLBACK = "debug"
    HOST  = "https://${google_container_cluster.infra.endpoint}"
    API_KEY = data.google_client_config.default.access_token
    CLUSTER_CA_CERTIFICATE = base64decode(google_container_cluster.infra.master_auth[0].cluster_ca_certificate,)
    }
  }
  depends_on = [
    google_container_node_pool.infra_preemptible_nodes,
    null_resource.ansible_istio_playbook,
    helm_release.cert-manager,

  ]
}
