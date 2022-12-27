variable "server_list" {
  default = { "job": {} }
}

locals {
  namespace = "sftp-jobs"
}