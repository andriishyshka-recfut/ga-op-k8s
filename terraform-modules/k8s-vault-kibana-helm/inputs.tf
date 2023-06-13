variable "ElasticSettings" {}
variable "KibanaSettings" {}
variable "Cluster" {}
variable "Color" {}
variable "Settings" {}

locals {
  globalSettings = var.ElasticSettings.globalSettings
  kibanaSettings = var.KibanaSettings
  httpServive    = "${local.globalSettings.clusterName}-coor"
}
