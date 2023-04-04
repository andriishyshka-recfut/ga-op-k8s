
module "gitlab-ce" {
  source         = "../../terraform-modules/k8s-vault-gitlab-ce"
  gitlab_list  = var.Settings.clusters[var.Cluster][var.Color].gitlab
  gitlab_values = local.gitlab_values
}