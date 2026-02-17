variable "Cluster" {}
variable "Color" {}
variable "Settings" {}
variable "OidcRedirectUri" {}
variable "StoreEsPasswordInVault" {}
variable "MinioAddress" {}
variable "BackupBucketName" {}
variable "BackupBucketBasePath" {}
variable "ElasticSettings" {}
variable "VaultAddress" {}

locals {
  httpServive    = "${local.globalSettings.clusterName}-coor"
  currentProject = var.Settings.gcpProject
  globalSettings = var.ElasticSettings.globalSettings
  nodePools      = var.ElasticSettings.nodePools
  combineSettings = {
    slackNotification = local.slackNotification,
    emailNotification = local.emailNotification,
    configAuth        = local.configAuth
  }

  vaultKeystoresPath = "secret/mw/elastic/keystores"
  persistentVolumes  = local.globalSettings.volumeExt ? [for node, data in local.nodePools : { for index in range(data.replicas) : "${local.globalSettings.clusterName}-${node}-${index}" => data.storage }] : []
  persistentVolumesDisks = { for new_name in flatten([ for nodepool in var.Settings.clusters[var.Cluster].persistent_resources.permanentDisks.elastic : [for disk in range(nodepool.count) : { name = nodepool.name, size = nodepool.size, index = disk, count = nodepool.count} ]]): "${new_name.name}-${new_name.index}" => new_name } 

  keystores          = { for key in lookup(local.globalSettings, "keystores", []) : key => "${local.vaultKeystoresPath}/${key}" }
}
