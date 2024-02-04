
resource "grafana_folder" "artifact" {
  org_id = grafana_organization.elastic.org_id
  provider = grafana.elastic
  title    = "#artifact"
  depends_on = [ helm_release.grafana-clients ]
}

resource "grafana_dashboard" "artifact" {
  org_id = grafana_organization.elastic.org_id
  provider    = grafana.elastic
  folder      = grafana_folder.artifact.id
  config_json = file("${path.module}/dashboards/artifact.json")
  depends_on = [ helm_release.grafana-clients ]
}


resource "grafana_folder" "dome" {
  org_id = grafana_organization.elastic.org_id
  provider = grafana.elastic
  title    = "#dome"
  depends_on = [ helm_release.grafana-clients ]
}

# resource "grafana_dashboard" "dome" {
#   provider    = grafana.elastic
#   folder      = grafana_folder.dome.id
#   config_json = file("${path.module}/dashboards/dome.json")
# }
resource "grafana_dashboard" "parsing_progress" {
  org_id = grafana_organization.elastic.org_id
  provider    = grafana.elastic
  folder      = grafana_folder.dome.id
  config_json = file("${path.module}/dashboards/dome-parsing-progress.json")
  depends_on = [ helm_release.grafana-clients ]
}


resource "grafana_folder" "minion" {
  org_id = grafana_organization.elastic.org_id
  provider = grafana.elastic
  title    = "#minion"
  depends_on = [ helm_release.grafana-clients ]
}

# resource "grafana_dashboard" "minion" {
#   provider    = grafana.elastic
#   folder      = grafana_folder.minion.id
#   config_json = file("${path.module}/dashboards/minion.json")
# }
resource "grafana_dashboard" "minion-sold" {
  org_id = grafana_organization.elastic.org_id
  provider    = grafana.elastic
  folder      = grafana_folder.minion.id
  config_json = file("${path.module}/dashboards/minion-sold.json")
  depends_on = [ helm_release.grafana-clients ]
}



resource "grafana_folder" "logstash" {
  org_id = grafana_organization.elastic.org_id
  provider = grafana.elastic
  title    = "#logstash"
}

resource "grafana_dashboard" "logstash" {
  org_id = grafana_organization.elastic.org_id
  provider    = grafana.elastic
  folder      = grafana_folder.logstash.id
  config_json = file("${path.module}/dashboards/logstash.json")
}


resource "grafana_folder" "general" {
  org_id = grafana_organization.elastic.org_id
  provider = grafana.elastic
  title    = "#General"
  depends_on = [ helm_release.grafana-clients ]
}

resource "grafana_dashboard" "general" {
  org_id = grafana_organization.elastic.org_id
  provider    = grafana.elastic
  folder      = grafana_folder.general.id
  config_json = file("${path.module}/dashboards/umbrella-dashboard.json")
  depends_on = [ helm_release.grafana-clients ]
}

