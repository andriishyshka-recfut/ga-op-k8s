variable "server_list" {
  default = { "job": {} }
}
variable "gcpProject" {}
variable "region" {}
variable "sftpgo_values" {}
locals {
  namespace = "sftpgo"
  minio_user = "sftpgo"
  server_name = "sftp-server"
  sftpgo_values = var.sftpgo_values
}