variable "ElasticSettings" {}
variable "BeatKibanaService" {}
variable "BeatElasticService" {}

locals {
  elasticSettings = var.ElasticSettings
}
