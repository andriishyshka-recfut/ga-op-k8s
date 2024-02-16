locals {
  index_dome     = split("\n", file("${path.module}/dome.txt"))
  index_minion   = split("\n", file("${path.module}/minion.txt"))
  index_artifact = split("\n", file("${path.module}/artifact.txt"))
}

resource "grafana_data_source" "dome" {
  provider            = grafana.elastic
  org_id              = local.org_id
  count               = length(local.index_dome)
  type                = "elasticsearch"
  name                = "dome-${element(local.index_dome, count.index)}"
  url                 = "http://red-coor.elastic.svc:9200"
  basic_auth_enabled  = "true"
  basic_auth_username = local.elasticUsername
  access_mode         = "proxy"
  database_name       = "dome-${element(local.index_dome, count.index)}*"
  is_default          = false
  json_data_encoded = jsonencode({
    timeField                  = "@timestamp"
    esVersion                  = "7.17.17"
    maxConcurrentShardRequests = 256
    timeInterval               = "10s"
  })
  secure_json_data_encoded = jsonencode({
    basicAuthPassword = local.elasticPassword
  })
}

resource "grafana_data_source" "minion" {
  provider            = grafana.elastic
  org_id              = local.org_id
  count               = length(local.index_minion)
  type                = "elasticsearch"
  name                = "minion-${element(local.index_minion, count.index)}"
  url                 = "http://red-coor.elastic.svc:9200"
  basic_auth_enabled  = "true"
  basic_auth_username = local.elasticUsername
  access_mode         = "proxy"
  database_name       = "${element(local.index_minion, count.index)}*"
  is_default          = false
  json_data_encoded = jsonencode({
    timeField                  = "timeStampLastSeen"
    esVersion                  = "7.17.17"
    maxConcurrentShardRequests = 256
    timeInterval               = "10s"
  })
  secure_json_data_encoded = jsonencode({
    basicAuthPassword = local.elasticPassword
  })
}

resource "grafana_data_source" "artifact" {
  provider            = grafana.elastic
  org_id              = local.org_id
  count               = length(local.index_artifact)
  type                = "elasticsearch"
  name                = "artifact-${element(local.index_artifact, count.index)}"
  url                 = "http://red-coor.elastic.svc:9200"
  basic_auth_enabled  = "true"
  basic_auth_username = local.elasticUsername
  access_mode         = "proxy"
  database_name       = "${element(local.index_artifact, count.index)}*"
  is_default          = false
  json_data_encoded = jsonencode({
    timeField                  = "@timestamp"
    esVersion                  = "7.17.17"
    maxConcurrentShardRequests = 256
    timeInterval               = "10s"
  })
  secure_json_data_encoded = jsonencode({
    basicAuthPassword = local.elasticPassword
  })
}

resource "grafana_data_source" "prod-filebeat" {
  provider            = grafana.elastic
  type                = "elasticsearch"
  org_id              = local.org_id
  name                = "prod-filebeat"
  url                 = "https://10.203.0.2:9222"
  basic_auth_enabled  = "true"
  basic_auth_username = local.elasticUsername
  access_mode         = "proxy"
  database_name       = "filebeat-*"
  is_default          = false
  json_data_encoded = jsonencode({
    timeField                  = "@timestamp"
    esVersion                  = local.esVersion
    maxConcurrentShardRequests = 256
    timeInterval               = "10s"
  })
  secure_json_data_encoded = jsonencode({
    basicAuthPassword = local.elasticPassword
  })
}
