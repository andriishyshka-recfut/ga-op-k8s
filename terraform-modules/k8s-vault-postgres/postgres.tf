data "vault_generic_secret" "harbor_token" {
  path = "secret/goharbor/docker_login"
}

resource "helm_release" "postgres_crds" {
  name                = "postgres-crds"
  namespace           = local.namespace
  chart               = "oci://harbor.regemini.io/helm/postgres-crds"
  wait                = true
  atomic              = true
  version             = var.Settings.clusters[var.Cluster].postgres.chart_version
  repository_username = data.vault_generic_secret.harbor_token.data.user
  repository_password = data.vault_generic_secret.harbor_token.data.password
  values = [
    templatefile("${path.module}/values.yaml.tftpl", { settings = var.Settings.clusters[var.Cluster].postgres,
    users = local.db_user_pass, minio = local.minio, pv_selector_label = local.pv_selector_label })
  ]
  depends_on = [helm_release.cnpg]
}

resource "null_resource" "ansible_validate_resources_postgres" {

  triggers = {
    playbook_contents = md5(file("${path.module}/../../ansible/validate_postgres.yml"))
    helm_release      = helm_release.postgres_crds.id
  }
  provisioner "local-exec" {
    command = <<COMMAND
    cd ${path.module}/../../ansible &&\
    ansible-playbook validate_postgres.yml

COMMAND
    environment = merge(local.ansibleEnvs, {
      name       = local.cluster_name
      kind       = "Cluster"
      apiVersion = "postgresql.cnpg.io/v1"
    })
  }
  depends_on = [
    helm_release.postgres_crds
  ]
}

resource "kubernetes_manifest" "post_script" {
  manifest = yamldecode(templatefile("${path.module}/postgres-job.yaml.tftpl", merge(
    { namespace = local.namespace },
    { secret_name = "postgres-superuser" },
    { tag = "v0.0.8" },
    { vault_role_name = "postgres" },
    { vault_role_path = "k8s-${var.Cluster}-${var.Color}" },
    { vault_addr = var.VaultAddress }
  )))
  depends_on = [null_resource.ansible_validate_resources_postgres]
}
