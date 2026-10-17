locals {
  kafka_strimzi_version = var.Settings.clusters[var.Cluster].versions.kafka.operator_chart_version

  create_kafka_crd = <<COMMAND
    set -x

    echo "Creating Kafka CRD"
    kubectl  --server ${data.vault_generic_secret.k8s_auth_active.data.HOST}  \
    --token ${data.vault_generic_secret.k8s_auth_active.data.k8s_sa_token}  \
    --insecure-skip-tls-verify=true apply -f \
    https://github.com/strimzi/strimzi-kafka-operator/releases/download/${local.kafka_strimzi_version}/strimzi-crds-${local.kafka_strimzi_version}.yaml
    sleep 10
COMMAND
}


data "vault_generic_secret" "k8s_auth_inactive" {
  path = local.inactiveClusterVaultPath
}

data "vault_generic_secret" "k8s_auth_active" {
  path = local.activeClusterVaultPath
}


resource "null_resource" "create_kafka_crd" {

  triggers = {
    command = md5(local.create_kafka_crd)
  }
  provisioner "local-exec" {
    interpreter = ["/bin/bash", "-c"]
    command     = local.create_kafka_crd
  }
}

module "fluxcd" {
  source     = "../../../terraform-modules/k8s-vault-fluxcd-resources"
  Cluster    = var.Cluster
  Color      = var.Color
  Values     = local.values
  depends_on = [null_resource.create_kafka_crd]
}

locals {
  values = {
    git-repositories = {
      kafka-topics = {
        url = "https://github.com/recfut/ga-op-kafka-topics.git",
        provider = "github",
        git_branch = "main"
      }
    },
    kustomizations = {
      kafka-topics = {
        kustomization_path = "./gitops",
        git_repository     = "kafka-topics"
      },
      kafka-init = {
        kustomization_path = "./kyverno-policies/kafka",
        git_repository     = "gitops"
      }
    }
  }
}


