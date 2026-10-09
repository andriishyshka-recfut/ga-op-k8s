variable "Cluster" {}
variable "Color" {}
variable "Settings" {}
variable "artifactoryRepoDomain" {}

locals {
  chartVersion = var.Settings.clusters[var.Cluster].versions.stakater.chart_version
#  appVersion   = var.Settings.clusters[var.Cluster].versions.stakater.app_version
  namespace    = "reloader"
}