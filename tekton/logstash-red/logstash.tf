module "logstash" {
  source         = "../../terraform-modules/k8s-vault-logstash-pipelines"
  logstash_list  = try(var.Settings.clusters[var.Cluster].logstash, var.Settings.clusters[var.Cluster][var.Color].logstash)
}