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

variable "Settings" { }

locals{
  currentProject  = var.Settings.gcpProject
}
