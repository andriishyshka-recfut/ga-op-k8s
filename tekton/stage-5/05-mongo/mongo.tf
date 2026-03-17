data "vault_generic_secret" "k8s_auth_inactive" {
  path = local.inactiveClusterVaultPath
}

data "vault_generic_secret" "k8s_auth_active" {
  path = local.activeClusterVaultPath
}

module "mongo6" {
  for_each                     = var.Settings.clusters[var.Cluster].mongo6
  source                       = "../../../terraform-modules/k8s-vault-mongo6"
  CredsPath                    = each.value.vaultPath
  MongoNs                      = each.value.namespace
  BackupSettings               = each.value.mongoMigrateSettings
  BackupBucket                 = each.value.backupBucket
  VolumeSize                   = each.value.volumeSize
  Replicas                     = each.value.replicas
  PvcPrefix                    = each.value.pvcPrefix
  InstanceName                 = each.key
  Cluster                      = var.Cluster
  Color                        = var.Color
  Settings                     = var.Settings
  ImageTag                     = each.value.imageTag
  Repository                   = each.value.repository
  Resources                    = try(each.value.resources, null)
  GkeClusterConnectionSettings = local.gkeClusterConnectionSettings
}

locals {
  clone_mongo_backups = <<COMMAND
    set -x

    echo "Clone mongo-auth backups"
    kubectl --server ${data.vault_generic_secret.k8s_auth_inactive.data.HOST}  \
    --token ${data.vault_generic_secret.k8s_auth_inactive.data.k8s_sa_token}  \
    --insecure-skip-tls-verify=true  \
    get perconaservermongodbbackup -n mongo-auth -o yaml |  kubectl  --server ${data.vault_generic_secret.k8s_auth_active.data.HOST}  \
    --token ${data.vault_generic_secret.k8s_auth_active.data.k8s_sa_token}  \
    --insecure-skip-tls-verify=true apply -f - 

    echo "Clone mongo-main backups"
    kubectl --server ${data.vault_generic_secret.k8s_auth_inactive.data.HOST}  \
    --token ${data.vault_generic_secret.k8s_auth_inactive.data.k8s_sa_token}  \
    --insecure-skip-tls-verify=true  \
    get perconaservermongodbbackup -n mongo -o yaml |  kubectl  --server ${data.vault_generic_secret.k8s_auth_active.data.HOST}  \
    --token ${data.vault_generic_secret.k8s_auth_active.data.k8s_sa_token}  \
    --insecure-skip-tls-verify=true apply -f - 
COMMAND
}


resource "null_resource" "create_mongo_crd" {
  depends_on = [module.mongo6]
  triggers = {
    command = md5(local.clone_mongo_backups)
  }
  provisioner "local-exec" {
    interpreter = ["/bin/bash", "-c"]
    command     = local.clone_mongo_backups
  }
}
