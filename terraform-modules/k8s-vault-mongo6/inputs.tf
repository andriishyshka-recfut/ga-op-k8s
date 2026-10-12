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
variable "Resources" {}

locals {
  ansibleEnvs = merge(var.GkeClusterConnectionSettings, {
    ANSIBLE_STDOUT_CALLBACK = "debug"
  })
  default_profile = {
    limit   = { memory = "2G", cpu = "1" }
    request = { memory = "1G", cpu = "0.25" }
  }

  profile = try(var.Resources, local.default_profile)

  limit   = local.profile.limit
  request = local.profile.request

  pv_disk_count = var.Settings.clusters[var.Cluster].persistent_resources.permanentDisks.services.mongo[var.InstanceName].count

  claim_prefix = "mongod-data-mongo-${var.InstanceName}"
  full_name    = "mongo-${var.InstanceName}"

  zones = var.Settings.clusters[var.Cluster].persistent_resources.permanentDisks.zones
  exporterImage = lookup(
    lookup(var.Settings.clusters[var.Cluster].mongo6, var.InstanceName, {}),
    "exporterImage",
    "percona/mongodb_exporter:0.47.2"
  )

}
