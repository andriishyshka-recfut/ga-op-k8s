resource "random_string" "minion" {
  length = 1
  lower  = false
}

resource "grafana_library_panel" "minion_graph" {
  provider  = grafana.elastic
  org_id    = local.org_id
  for_each   = local.index_minion_map
  name       = "minion-${each.key}-${random_string.minion.id}"
  folder_uid = grafana_folder.minion.uid
  depends_on = [
    grafana_data_source.minion
  ]
  model_json = jsonencode({
    "aliasColors" : {},
    "bars" : false,
    "dashLength" : 10,
    "dashes" : false,
    "datasource" : "${grafana_data_source.minion[each.key].name}",
    "description" : "${each.key}",
    "fieldConfig" : {
      "defaults" : {
        "links" : []
      },
      "overrides" : []
    },
    "fill" : 1,
    "fillGradient" : 0,
    "gridPos" : {
      "h" : 6,
      "w" : 24,
      "x" : 0,
      "y" : 0
    },
    "hiddenSeries" : false,
    "legend" : {
      "avg" : false,
      "current" : false,
      "max" : false,
      "min" : false,
      "show" : true,
      "total" : false,
      "values" : false
    },
    "lines" : true,
    "linewidth" : 1,
    "nullPointMode" : "null",
    "options" : {
      "alertThreshold" : true
    },
    "percentage" : false,
    "pluginVersion" : "9.0.4",
    "pointradius" : 2,
    "points" : false,
    "renderer" : "flot",
    "seriesOverrides" : [],
    "spaceLength" : 10,
    "stack" : false,
    "steppedLine" : false,
    "targets" : [
      {
        "alias" : "",
        "bucketAggs" : [
          {
            "field" : "recordType",
            "id" : "3",
            "settings" : {
              "min_doc_count" : "1",
              "order" : "desc",
              "orderBy" : "_term",
              "size" : "10"
            },
            "type" : "terms"
          },
          {
            "field" : "timeStampLastSeen",
            "id" : "2",
            "settings" : {
              "interval" : "auto"
            },
            "type" : "date_histogram"
          }
        ],
        "metrics" : [
          {
            "id" : "1",
            "type" : "count"
          }
        ],
        "query" : "",
        "refId" : "A",
        "timeField" : "timeStampLastSeen"
      }
    ],
    "thresholds" : [],
    "timeRegions" : [],
    "title" : "${each.key}",
    "tooltip" : {
      "shared" : true,
      "sort" : 0,
      "value_type" : "individual"
    },
    "type" : "graph",
    "xaxis" : {
      "mode" : "time",
      "show" : true,
      "values" : []
    },
    "yaxes" : [
      {
        "format" : "short",
        "logBase" : 1,
        "show" : true
      },
      {
        "format" : "short",
        "logBase" : 1,
        "show" : true
      }
    ],
    "yaxis" : {
      "align" : false
    }
  })
}


locals {
  grafana_library_minion_graph = [
    for name in local.index_minion :
    merge(jsondecode(grafana_library_panel.minion_graph[name].model_json), {
      libraryPanel = {
        name = grafana_library_panel.minion_graph[name].name
        uid  = grafana_library_panel.minion_graph[name].uid
      }
    })
  ]
}

resource "grafana_dashboard" "minion_library_panel" {
  provider = grafana.elastic
  org_id   = local.org_id
  folder   = grafana_folder.minion.id
  depends_on = [
    grafana_library_panel.minion_graph
  ]
  config_json = jsonencode({
    "panels" : concat(local.grafana_library_minion_graph)
    "annotations" : {
      "list" : [
        {
          "builtIn" : 1,
          "datasource" : {
            "type" : "datasource",
            "uid" : "grafana"
          },
          "enable" : true,
          "hide" : true,
          "iconColor" : "rgba(0, 211, 255, 1)",
          "name" : "Annotations & Alerts",
          "target" : {
            "limit" : 100,
            "matchAny" : false,
            "tags" : [],
            "type" : "dashboard"
          },
          "type" : "dashboard"
        }
      ]
    },
    "editable" : true,
    "fiscalYearStartMonth" : 0,
    "graphTooltip" : 0,
    "id" : 24,
    "links" : [],
    "liveNow" : false,
    "refresh" : "",
    "schemaVersion" : 36,
    "style" : "dark",
    "tags" : [],
    "templating" : {
      "list" : []
    },
    "time" : {
      "from" : "now-2d",
      "to" : "now"
    },
    "timepicker" : {
      "refresh_intervals" : [
        "5s",
        "10s",
        "30s",
        "1m",
        "5m",
        "15m",
        "30m",
        "1h",
        "2h",
        "1d"
      ],
      "time_options" : [
        "5m",
        "15m",
        "1h",
        "6h",
        "12h",
        "24h",
        "2d",
        "7d",
        "30d"
      ]
    },
    "timezone" : "",
    "title" : "MINION (AIO)",
    "version" : 1,
    "weekStart" : ""
  })
}
