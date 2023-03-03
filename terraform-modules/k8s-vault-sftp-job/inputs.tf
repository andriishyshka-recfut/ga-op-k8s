variable "job_list" {
  default = { "job": {} }
}

locals {
  namespace              = "sftp-jobs"
  bucket                 = "minio-logstash-pipelines-orbital-wording-233917"
  minio_user             = "logstash-user"
  cron                   = "0 1 * * *"
  delivery_method        = "" # sftp email s3
  archive                = "" # zip or gz
  create_checksum        = false
  gpg_encrypt            = false
  client_notify          = "" # email
  rescue_email_notify    = false
  aws_s3_bucket          = "" # s3 bucket name
  file_ext               = "" # csv json
  #SFTP values
  sftp_host              = "sftp-server-main"
  sftp_user              = "user"
  sftp_port              = "22"
  sftp_use_gss_api_auth  = "false"
  sftp_destination = "share/received-data"
  #Email values
  email_cc               = "threat@geminiadvisory.io"
  email_subject          = "FEED-NG"
  #EmailNotify values
  email_notify_cc        = ""
  email_notify_subject   = ""
  #RescueEmailNotify values
  rescue_email_subject   = "Failed job"

  namespaces             = toset(distinct([for k, v in var.job_list: lookup(v, "namespace", local.namespace )]))
  minio_users            = {for k,v in { for k, v in var.job_list: lookup(v, "minio_user", local.minio_user) => lookup(v, "namespace", local.namespace)... }: k => distinct(v)}
}