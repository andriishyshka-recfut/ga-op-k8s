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
  limit         = var.Cluster == "production" ? { "memory" : "4G", "cpu" : "3" } : { "memory" : "2G", "cpu" : "1" }
  request       = var.Cluster == "production" ? { "memory" : "3G", "cpu" : "1" } : { "memory" : "1G", "cpu" : "0.25" }
  pv_disk_count = var.Cluster == "production" ? 0 : 3
  encryption_keys_count = var.Cluster == "production" ? 0 : 1

  claim_prefix = var.Cluster == "production" ? "mongod-data-${var.Color}" : "mongod-data-mongo-${var.InstanceName}"
  target_label = var.PvcPrefix
  full_name = var.Cluster == "production" ? var.Color : "mongo-${var.InstanceName}"

  pvc_config = {
    type = "persistent-claim"
    selector = {
      target = var.PvcPrefix
    }
    deleteClaim = true
    class       = ""
  }
}
