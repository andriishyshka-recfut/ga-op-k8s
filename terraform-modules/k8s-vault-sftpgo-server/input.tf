variable "server_list" {
  default = { "job": {} }
}
variable "gcpProject" {}
variable "region" {}
locals {
  namespace = "sftpgo"
  minio_user = "sftpgo"
  server_name = "sftp-server"
}