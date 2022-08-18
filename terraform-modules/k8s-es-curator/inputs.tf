variable "ElasticName" {
  default = "monitoring"
}

variable "Namespace" {
  default = "monitoring"
}

variable "Actions" {
  default = ""
}

variable "NamePrefix" {
  default = ""
}

variable "Settings" {}

variable "BackupBucketName" {}

variable "BackupBucketBasePath" {}

locals {
  currentProject = var.Settings.gcpProject
}
