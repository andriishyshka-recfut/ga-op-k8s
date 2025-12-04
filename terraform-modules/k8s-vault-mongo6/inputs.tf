variable "CredsPath" {
  default = "secret/mongo/production"
}

variable "MongoNs" {}
variable "BackupBucket" {}
variable "VolumeSize" {}
variable "Replicas" {}
variable "BackupSettings" {}
variable "Cluster" {}
variable "InstanceName" {}
variable "Color" {}
variable "GkeClusterConnectionSettings" {}
variable "ImageTag" {}
variable "Repository" {}
variable "Settings" {}
variable "PvcPrefix" {}

locals {
  ansibleEnvs = merge(var.GkeClusterConnectionSettings, {
    ANSIBLE_STDOUT_CALLBACK = "debug"
  })
  limit         = var.Cluster == "production" ? { "memory" : "5G", "cpu" : "3" } : { "memory" : "2G", "cpu" : "1" }
  request       = var.Cluster == "production" ? { "memory" : "4G", "cpu" : "1" } : { "memory" : "1G", "cpu" : "0.25" }
  pv_disk_count = var.Settings.clusters[var.Cluster].persistent_resources.permanentDisks.mongo6.count

  claim_prefix = "mongod-data-mongo-${var.InstanceName}"
  target_label = var.PvcPrefix
  full_name = "mongo-${var.InstanceName}"

  zones = var.Settings.clusters[var.Cluster].persistent_resources.permanentDisks.zones
}
