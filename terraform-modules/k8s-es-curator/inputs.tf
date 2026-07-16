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

variable "MinioAddress" {}

variable "BackupBucketName" {}

variable "BackupBucketBasePath" {}

variable "EsService" {}

variable "EsCreds" {}

locals {
  currentProject = var.Settings.gcpProject
  es_host = "mon-es-http.monitoring.svc"
}
