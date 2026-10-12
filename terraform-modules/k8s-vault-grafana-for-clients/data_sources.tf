# locals {
#   index_dome     = split("\n", file("${path.module}/dome.txt"))
#   index_minion   = split("\n", file("${path.module}/minion.txt"))
#   index_artifact = split("\n", file("${path.module}/artifact.txt"))
# }

locals {
  index_dome = [
    for name in split("\n", trimspace(file("${path.module}/dome.txt"))) :
    trimspace(name)
    if trimspace(name) != ""
  ]
  index_dome_map = {
    for name in local.index_dome : name => name
  }

  index_minion = [
    for name in split("\n", trimspace(file("${path.module}/minion.txt"))) :
    trimspace(name)
    if trimspace(name) != ""
  ]
    index_minion_map = {
    for name in local.index_minion : name => name
  }

  index_artifact = [
    for name in split("\n", trimspace(file("${path.module}/artifact.txt"))) :
    trimspace(name)
    if trimspace(name) != ""
  ]
    index_artifact_map = {
    for name in local.index_artifact : name => name
  }  
}

resource "grafana_data_source" "dome" {
  provider            = grafana.elastic
  org_id              = local.org_id
  for_each            = local.index_dome_map
  type                = "elasticsearch"
  name                = "dome-${each.key}"
  url                 = "http://red-coor.elastic.svc:9200"
  basic_auth_enabled  = "true"
  basic_auth_username = local.elasticUsername
  access_mode         = "proxy"
  database_name       = "dome-${each.key}*"
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
  for_each            = local.index_minion_map
  type                = "elasticsearch"
  name                = "minion-${each.key}"
  url                 = "http://red-coor.elastic.svc:9200"
  basic_auth_enabled  = "true"
  basic_auth_username = local.elasticUsername
  access_mode         = "proxy"
  database_name       = "minion-${each.key}*"
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
  for_each            = local.index_artifact_map
  type                = "elasticsearch"
  name                = "artifact-${each.key}"
  url                 = "http://red-coor.elastic.svc:9200"
  basic_auth_enabled  = "true"
  basic_auth_username = local.elasticUsername
  access_mode         = "proxy"
  database_name       = "artifact-${each.key}*"
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
    basicAuthPassword               = local.elasticPassword
    disableTLSCertificateValidation = "true"
  })
}
