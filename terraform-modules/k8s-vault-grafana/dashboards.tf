
resource "grafana_folder" "artifact" {
  provider = grafana.elastic
  title    = "#artifact"
}

resource "grafana_dashboard" "artifact" {
  provider    = grafana.elastic
  folder      = grafana_folder.artifact.id
  config_json = file("${path.module}/dashboards/artifact.json")
}


resource "grafana_folder" "dome" {
  provider = grafana.elastic
  title    = "#dome"
}

# resource "grafana_dashboard" "dome" {
#   provider    = grafana.elastic
#   folder      = grafana_folder.dome.id
#   config_json = file("${path.module}/dashboards/dome.json")
# }
resource "grafana_dashboard" "parsing_progress" {
  provider    = grafana.elastic
  folder      = grafana_folder.dome.id
  config_json = file("${path.module}/dashboards/dome-parsing-progress.json")
}


resource "grafana_folder" "minion" {
  provider = grafana.elastic
  title    = "#minion"
}

# resource "grafana_dashboard" "minion" {
#   provider    = grafana.elastic
#   folder      = grafana_folder.minion.id
#   config_json = file("${path.module}/dashboards/minion.json")
# }
resource "grafana_dashboard" "minion-sold" {
  provider    = grafana.elastic
  folder      = grafana_folder.minion.id
  config_json = file("${path.module}/dashboards/minion-sold.json")
}



resource "grafana_folder" "logstash" {
  provider = grafana.elastic
  title    = "#logstash"
}

resource "grafana_dashboard" "logstash" {
  provider    = grafana.elastic
  folder      = grafana_folder.logstash.id
  config_json = file("${path.module}/dashboards/logstash.json")
}


resource "grafana_folder" "general" {
  provider = grafana.elastic
  title    = "#General"
}

resource "grafana_dashboard" "general" {
  provider    = grafana.elastic
  folder      = grafana_folder.general.id
  config_json = file("${path.module}/dashboards/umbrella-dashboard.json")
}

