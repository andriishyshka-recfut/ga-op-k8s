variable "gitlab_list" {}
variable "gitlab_values" {}
variable "Cluster" {}
variable "Color" {}
variable "Settings" {}
locals {
  domain            = "gitlab.regemini.com"
  namespace         = "gitlab"
  gitlab_values     = var.gitlab_values
  runner_minio_user = "gitlab-runner"

}
