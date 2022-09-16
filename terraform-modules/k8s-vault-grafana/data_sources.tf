locals {
  index_dome     = split("\n", file("${path.module}/dome.txt"))
  index_minion   = split("\n", file("${path.module}/minion.txt"))
  index_artifact = split("\n", file("${path.module}/artifact.txt"))
}

resource "grafana_data_source" "dome" {
  provider            = grafana.elastic
  count               = length(local.index_dome)
  type                = "elasticsearch"
  name                = "dome-${element(local.index_dome, count.index)}"
  url                 = "http://elastic-internal-proxy.elastic:9200"
  basic_auth_enabled  = "true"
  basic_auth_username = local.elasticUsername
  access_mode         = "proxy"
  database_name       = "dome-${element(local.index_dome, count.index)}*"
  is_default          = false
  json_data {
    time_field                    = "@timestamp"
    es_version                    = "7.17.0"
    max_concurrent_shard_requests = "256"
    time_interval                 = "10s"
  }
  secure_json_data {
    basic_auth_password = local.elasticPassword
  }
}

resource "grafana_data_source" "minion" {
  provider            = grafana.elastic
  count               = length(local.index_minion)
  type                = "elasticsearch"
  name                = "minion-${element(local.index_minion, count.index)}"
  url                 = "http://elastic-internal-proxy.elastic:9200"
  basic_auth_enabled  = "true"
  basic_auth_username = local.elasticUsername
  access_mode         = "proxy"
  database_name       = "${element(local.index_minion, count.index)}*"
  is_default          = false
  json_data {
    time_field                    = "timeStampLastSeen"
    es_version                    = "7.17.0"
    max_concurrent_shard_requests = "256"
    time_interval                 = "10s"
  }
  secure_json_data {
    basic_auth_password = local.elasticPassword
  }
}

resource "grafana_data_source" "artifact" {
  provider            = grafana.elastic
  count               = length(local.index_artifact)
  type                = "elasticsearch"
  name                = "artifact-${element(local.index_artifact, count.index)}"
  url                 = "http://elastic-internal-proxy.elastic:9200"
  basic_auth_enabled  = "true"
  basic_auth_username = local.elasticUsername
  access_mode         = "proxy"
  database_name       = "${element(local.index_artifact, count.index)}*"
  is_default          = false
  json_data {
    time_field                    = "@timestamp"
    es_version                    = "7.17.0"
    max_concurrent_shard_requests = "256"
    time_interval                 = "10s"
  }
  secure_json_data {
    basic_auth_password = local.elasticPassword
  }
}

resource "grafana_data_source" "logstash" {
  provider            = grafana.elastic
  type                = "elasticsearch"
  name                = "logstash"
  url                 = "http://elastic-internal-proxy.elastic:9200"
  basic_auth_enabled  = "true"
  basic_auth_username = local.elasticUsername
  access_mode         = "proxy"
  database_name       = "logstash"
  is_default          = false
  json_data {
    time_field = "@timestamp"
    # interval                      = "Daily"
    es_version                    = "7.17.0"
    max_concurrent_shard_requests = "256"
    time_interval                 = "10s"
  }
  secure_json_data {
    basic_auth_password = local.elasticPassword
  }
}
