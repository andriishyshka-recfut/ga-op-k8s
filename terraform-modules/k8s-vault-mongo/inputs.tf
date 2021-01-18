

locals {
  mongoNs = "mongo"
}

variable "CredsPath" {
  default = "secret/mongo/production"
}
