provider "vault" {
  # address         = "http://127.0.0.1:8200"
  address         = "https://vault.infra.digaweb.com"
  skip_tls_verify = true
}

data "vault_generic_secret" "k8s_auth" {
  path = "secret/kubernetes-green"
}

locals {
  es_values     = yamldecode(file("es_values.yaml"))
  beats_values  = yamldecode(file("beats_values.yaml"))
  kibana_values = yamldecode(file("kibana_values.yaml"))
}

provider "helm" {
  # alias = "helm"
  kubernetes {
    load_config_file       = false
    host                   = data.vault_generic_secret.k8s_auth.data.HOST
    cluster_ca_certificate = data.vault_generic_secret.k8s_auth.data.CLUSTER_CA_CERTIFICATE
    token                  = data.vault_generic_secret.k8s_auth.data.k8s_sa_token
  }
}

provider "kubernetes" {
  # alias                  = "kubernetes"
  load_config_file       = false
  host                   = data.vault_generic_secret.k8s_auth.data.HOST
  cluster_ca_certificate = data.vault_generic_secret.k8s_auth.data.CLUSTER_CA_CERTIFICATE
  token                  = data.vault_generic_secret.k8s_auth.data.k8s_sa_token
}

resource "helm_release" "elasticsearch" {
  name   = "elastic"
  chart  = "./elasticsearch"
  wait   = true
  atomic = true
  values = [
    yamlencode(local.es_values)
  ]
  depends_on = [
    kubernetes_namespace.namespace,
    kubernetes_secret.gcs-credentials
  ]
}

resource "helm_release" "beat" {
  name   = "beats"
  chart  = "./beats"
  wait   = true
  atomic = true
  values = [
    yamlencode(local.beats_values)
  ]
  depends_on = [
    null_resource.ansible_validate_kibana
  ]
}

resource "helm_release" "kibana" {
  name   = "kibana"
  chart  = "./kibana"
  wait   = true
  atomic = true
  values = [
    yamlencode(local.kibana_values)
  ]
  depends_on = [
    null_resource.ansible_validate_resources
  ]
}

resource "null_resource" "ansible_validate_resources" {

  triggers = {
    playbook_contents = md5(file("validate.yml"))
    helm_release      = helm_release.elasticsearch.id
  }
  provisioner "local-exec" {
    command = <<COMMAND
    ansible-playbook validate.yml \
      -e 'ansible_python_interpreter=/usr/bin/python3'
COMMAND
    environment = {
      ANSIBLE_STDOUT_CALLBACK = "debug"
      HOST                    = data.vault_generic_secret.k8s_auth.data.HOST
      # API_TOKEN               = data.google_client_config.google.access_token
      API_TOKEN              = data.vault_generic_secret.k8s_auth.data.k8s_sa_token
      CLUSTER_CA_CERTIFICATE = data.vault_generic_secret.k8s_auth.data.CLUSTER_CA_CERTIFICATE
      # ES_LOGIN                = "elastic"
      # ES_PASSWORD             = base64decode(data.kubernetes_secret.es_password.data.elastic)
      name       = local.es_values.esName
      namespace  = local.es_values.namespace
      kind       = "Elasticsearch"
      apiVersion = "elasticsearch.k8s.elastic.co/v1"
    }
  }
  depends_on = [
    helm_release.elasticsearch
  ]
}

resource "null_resource" "ansible_validate_kibana" {

  triggers = {
    playbook_contents = md5(file("validate.yml"))
    helm_release      = helm_release.kibana.id
  }
  provisioner "local-exec" {
    command = <<COMMAND
    ansible-playbook validate.yml \
      -e 'ansible_python_interpreter=/usr/bin/python3'
COMMAND
    environment = {
      ANSIBLE_STDOUT_CALLBACK = "debug"
      HOST                    = data.vault_generic_secret.k8s_auth.data.HOST
      # API_TOKEN               = data.google_client_config.google.access_token
      API_TOKEN              = data.vault_generic_secret.k8s_auth.data.k8s_sa_token
      CLUSTER_CA_CERTIFICATE = data.vault_generic_secret.k8s_auth.data.CLUSTER_CA_CERTIFICATE
      # ES_LOGIN                = "elastic"
      # ES_PASSWORD             = base64decode(data.kubernetes_secret.es_password.data.elastic)
      name       = local.kibana_values.name
      namespace  = local.kibana_values.namespace
      kind       = "Kibana"
      apiVersion = "kibana.k8s.elastic.co/v1beta1"
    }
  }
  depends_on = [
    helm_release.kibana
  ]
}

data "kubernetes_secret" "es_password" {
  # provider = kubernetes.kubernetes
  metadata {
    name      = "${local.es_values.esName}-es-elastic-user"
    namespace = local.es_values.namespace
  }
  depends_on = [helm_release.elasticsearch]
}
resource "vault_generic_secret" "example" {
  path = "secret/elasticsearch-admin/${local.es_values.esName}"

  data_json = <<EOT
{
  "username":   "elastic",
  "password": "${data.kubernetes_secret.es_password.data.elastic}"
}
EOT
}
# output "creds" {
#   value = "elastic:${data.kubernetes_secret.es_password.data.elastic}"
# }

resource "kubernetes_namespace" "namespace" {
  metadata {

    labels = {
      istio-injection = "enabled"
    }

    name = local.es_values.namespace
  }
}

resource "kubernetes_secret" "gcs-credentials" {
  metadata {
    name      = "gcs-credentials"
    namespace = kubernetes_namespace.namespace.metadata[-1].name
  }

  data = {
    "gcs.client.default.credentials_file" = base63decode(google_service_account_key.es-key.private_key)
  }

  # type = "Opaque"
}

