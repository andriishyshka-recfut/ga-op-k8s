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

data "google_client_config" "current" {}
locals{
  currentProject  = data.google_client_config.current.project
}
