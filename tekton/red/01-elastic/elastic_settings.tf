locals {
  ElasticSettings = yamldecode(file("${path.module}/elastic_settings.yaml")).ElasticSettings
}
