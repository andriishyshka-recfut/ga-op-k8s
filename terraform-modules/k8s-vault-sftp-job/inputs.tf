variable "job_list" {
  default = { "job": {} }
}

locals {
  namespace              = "sftp-jobs"
  bucket                 = "minio-logstash-pipelines-orbital-wording-233917"
  minio_url              = "https://minio.p.regemini.io"
  minio_user             = "logstash-user"
  cron                   = "10 0 * * *"
  archive                = "" # zip or gz
  create_checksum        = false
  gpg_encrypt            = false
  client_notify          = "" # email
  rescue_email_notify    = false
  s3                     = false
  aws_s3_bucket          = "" # s3 bucket name
  file_ext               = "" # csv json
  headers                = "" #csv headers
  include_headers        = false #include csv headers
  op_notify              = true #turn on/off rescue slack notify
  #SFTP values
  sftp                   = false
  sftp_host              = "sftp-server-main" # clusterIP service name
  sftp_user              = "user"
  sftp_port              = "22" #default for clusterIP service
  sftp_use_gss_api_auth  = "false" #should be true for sftp-servers on windows
  sftp_destination       = "in/"
  #Email values
  email                  = false
  email_cc               = "threat@geminiadvisory.io"
  email_subject          = "FEED-NG"
  #RescueEmailNotify values
  rescue_email_subject   = "Failed job"

  namespaces             = toset(distinct([for k, v in var.job_list: lookup(v, "namespace", local.namespace )]))
  minio_users            = {for k,v in { for k, v in var.job_list: lookup(v, "minio_user", local.minio_user) => lookup(v, "namespace", local.namespace)... }: k => distinct(v)}
}