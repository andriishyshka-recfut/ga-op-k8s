variable "server_list" {
  default = { "job": {} }
}
variable "gcpProject" {}
variable "region" {}
variable "sftpgo_version" {}
locals {
  namespace = "sftpgo"
  minio_user = "sftpgo"
  server_name = "sftp-server"
}