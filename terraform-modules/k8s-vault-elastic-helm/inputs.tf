variable "Cluster" {}
variable "Color" {}
variable "Settings" {}
variable "OidcRedirectUri" {}
variable "StoreEsPasswordInVault" {}
variable "MinioAddress" {}
variable "BackupBucketName" {}
variable "BackupBucketBasePath" {}
variable "ElasticSettings" {}

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
}
