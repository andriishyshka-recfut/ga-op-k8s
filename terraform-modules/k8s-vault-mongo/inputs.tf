variable "CredsPath" {
  default = "secret/mongo/production"
}

variable "MongoNs" {}
variable "BackupBucket" {}
variable "VolumeSize" {}
variable "Replicas" {}
variable "BackupSettings" {}
variable "Cluster" {}
variable "Color" {}
variable "GkeClusterConnectionSettings" {}
variable "ImageTag" {}
variable "Repository" {}

locals {
  ansibleEnvs = merge(var.GkeClusterConnectionSettings, {
    ANSIBLE_STDOUT_CALLBACK = "debug"
  })
   limit = var.Cluster == "production" ? {"memory": "4G", "cpu": "3"} : {"memory": "2G", "cpu": "1"}
   request = var.Cluster == "production" ? {"memory": "3G", "cpu": "1"} : {"memory": "1G", "cpu": "0.25"}
}
