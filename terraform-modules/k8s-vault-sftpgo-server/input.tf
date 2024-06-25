variable "server_list" {
  default = { "job": {} }
}
variable "gcpProject" {}
variable "region" {}
variable "Settings" {}
variable "Cluster" {}
variable "Color" {}

locals {
  namespace = "sftpgo"
  minio_user = "sftpgo"
  server_name = "sftp-server"
  postgres_port = "5432"
  postgres_url  = "gitlab-postgresql.gitlab.svc"
  minio_url = "https://minio.p.regemini.io"
  minio_bucket = "minio-sftpgo-orbital-wording"
  chart_version = lookup(var.Settings.clusters[var.Cluster].versions.sftpgo, "chart_version", "0.19.0")
  image_tag = lookup(var.Settings.clusters[var.Cluster].versions.sftpgo, "image_tag", "v2.5.6")
  postgresql_chart_version = "15.5.7"
  postgresql_version = "14.8.0"
}