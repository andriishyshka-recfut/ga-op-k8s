variable "gitlab_list" {}
variable "gitlab_values" {}
locals {
  domain       = "gitlab.regemini.com"
  namespace    = "gitlab"
  gitlab_values = var.gitlab_values
}