variable "ElasticName" {
  default = "elastic"
}

variable "Namespace" {
  default = "elastic"
}

variable "Actions" {
  default = ""
}

variable "NamePrefix" {
  default = "reindex"
}

locals {
  Actions = file("${path.root}/actions.yaml")
  ES_HOST = "elastic-es-http"
}
