variable "ElasticSettings" {}
variable "KibanaSettings" {}
variable "Cluster" {}
variable "Color" {}
variable "Settings" {}

locals {
  globalSettings = var.ElasticSettings.globalSettings
  kibanaSettings = var.KibanaSettings
  httpServive    = "${local.globalSettings.clusterName}-coor"
  limit          = var.Cluster == "production" ? { "memory" : "2G", "cpu" : "1" } : { "memory" : "1G", "cpu" : "500m" }
  request        = var.Cluster == "production" ? { "memory" : "1G", "cpu" : "1" } : { "memory" : "256Mi", "cpu" : "100m" }
  order_counter  = { for kibana, kibana_data in local.kibanaSettings : kibana => lookup(kibana_data, "basic_auth", false) ? 1 : 0 }

}
