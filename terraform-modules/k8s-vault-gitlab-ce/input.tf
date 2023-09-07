variable "gitlab_list" {}
variable "gitlab_values" {}
variable "helm_version" {}
variable "gitlab_version" {}
locals {
  domain       = "gitlab.regemini.com"
  namespace    = "gitlab"
  gitlab_values = var.gitlab_values
}