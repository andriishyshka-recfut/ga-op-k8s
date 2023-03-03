
module "sftp-cronjob" {
  source         = "../../terraform-modules/k8s-vault-sftp-job"
  job_list       = var.Settings.clusters[var.Cluster].sftp-cronjob == {} ? local.sftpJobList : {}
}