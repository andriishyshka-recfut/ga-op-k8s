resource "random_string" "dome" {
  length = 1
  lower  = true
}

resource "grafana_library_panel" "dome_graph" {
  provider  = grafana.elastic
  org_id    = local.org_id
  for_each   = local.index_dome_map
  name       = "dome-${each.key}-${random_string.dome.id}"
  folder_uid = grafana_folder.dome.uid
  depends_on = [
    grafana_data_source.dome
  ]
  model_json = jsonencode({
    "aliasColors" : {},
    "version" : 1,
    "bars" : false,
    "dashLength" : 10,
    "dashes" : false,
    "datasource" : "${grafana_data_source.dome[each.key].name}",
    "fill" : 1,
    "fillGradient" : 0,
    "gridPos" : {
      "h" : 6,
      "w" : 16,
      "x" : 0,
      "y" : 0
    },
    "hiddenSeries" : false,
    "legend" : {
      "alignAsTable" : false,
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
        "bucketAggs" : [
          {
            "fake" : true,
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
            "field" : "@timestamp",
            "id" : "2",
            "settings" : {
              "interval" : "auto",
              "min_doc_count" : 0,
              "trimEdges" : 0
            },
            "type" : "date_histogram"
          }
        ],
        "metrics" : [
          {
            "field" : "select field",
            "id" : "1",
            "type" : "count"
          }
        ],
        "queryType" : "randomWalk",
        "refId" : "A",
        "timeField" : "@timestamp"
      },
      {
        "alias" : "POST added",
        "bucketAggs" : [
          {
            "field" : "timeStampAdded",
            "id" : "2",
            "settings" : {
              "interval" : "auto"
            },
            "type" : "date_histogram"
          }
        ],
        "hide" : false,
        "metrics" : [
          {
            "id" : "1",
            "type" : "count"
          }
        ],
        "query" : "",
        "refId" : "B",
        "timeField" : "@timestamp"
      },
      {
        "alias" : "PROFILE lastSeen",
        "bucketAggs" : [
          {
            "field" : "timeStampLastSeen",
            "id" : "2",
            "settings" : {
              "interval" : "auto"
            },
            "type" : "date_histogram"
          }
        ],
        "hide" : false,
        "metrics" : [
          {
            "id" : "1",
            "type" : "count"
          }
        ],
        "query" : "",
        "refId" : "C",
        "timeField" : "@timestamp"
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

resource "grafana_library_panel" "dome_table_old" {
  provider  = grafana.elastic
  org_id    = local.org_id
  for_each   = local.index_dome_map
  name       = "dome-table-${each.key}-${random_string.dome.id}"
  folder_uid = grafana_folder.dome.uid
  depends_on = [
    grafana_data_source.dome
  ]
  model_json = jsonencode({
    "columns" : [],
    "datasource" : "${grafana_data_source.dome[each.key].name}",
    "fontSize" : "100%",
    "gridPos" : {
      "h" : 6,
      "w" : 8,
      "x" : 16,
      "y" : 0
    },
    "links" : [],
    "scroll" : true,
    "showHeader" : true,
    "sort" : {
      "desc" : false
    },
    "styles" : [
      {
        "alias" : "Last Time",
        "align" : "auto",
        "dateFormat" : "YYYY-MM-DD HH:mm:ss",
        "pattern" : "Max",
        "type" : "date"
      },
      {
        "alias" : "",
        "align" : "auto",
        "colors" : [
          "rgba(245, 54, 54, 0.9)",
          "rgba(237, 129, 40, 0.89)",
          "rgba(50, 172, 45, 0.97)"
        ],
        "decimals" : 2,
        "pattern" : "/.*/",
        "thresholds" : [],
        "type" : "number",
        "unit" : "short"
      }
    ],
    "targets" : [
      {
        "bucketAggs" : [
          {
            "field" : "recordType",
            "id" : "2",
            "settings" : {
              "min_doc_count" : 1,
              "order" : "desc",
              "orderBy" : "_term",
              "size" : "10"
            },
            "type" : "terms"
          }
        ],
        "metrics" : [
          {
            "field" : "select field",
            "id" : "1",
            "meta" : {},
            "settings" : {},
            "type" : "count"
          }
        ],
        "refId" : "A",
        "timeField" : "@timestamp"
      },
      {
        "bucketAggs" : [
          {
            "field" : "recordType",
            "id" : "2",
            "settings" : {
              "min_doc_count" : 1,
              "order" : "desc",
              "orderBy" : "_term",
              "size" : "10"
            },
            "type" : "terms"
          }
        ],
        "metrics" : [
          {
            "field" : "@timestamp",
            "id" : "1",
            "meta" : {},
            "settings" : {},
            "type" : "max"
          }
        ],
        "refId" : "B",
        "timeField" : "@timestamp"
      }
    ],
    "title" : "${each.key}",
    "transform" : "table",
    "type" : "table-old"
  })
}

locals {
  grafana_library_dome_graph = [
    for name in local.index_dome :
    merge(jsondecode(grafana_library_panel.dome_graph[name].model_json), {
      libraryPanel = {
        name = grafana_library_panel.dome_graph[name].name
        uid  = grafana_library_panel.dome_graph[name].uid
      }
    })
  ]

  grafana_library_table = [
    for name in local.index_dome :
    merge(jsondecode(grafana_library_panel.dome_table_old[name].model_json), {
      libraryPanel = {
        name = grafana_library_panel.dome_table_old[name].name
        uid  = grafana_library_panel.dome_table_old[name].uid
      }
    })
  ]
}

resource "grafana_dashboard" "dome_library_panel" {
  provider = grafana.elastic
  org_id   = local.org_id
  folder   = grafana_folder.dome.id
  depends_on = [
    grafana_library_panel.dome_graph
  ]
  config_json = jsonencode({
    "panels" : concat(local.grafana_library_dome_graph, local.grafana_library_table)
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
    "dome_graphTooltip" : 0,
    "id" : 2556,
    "links" : [],
    "liveNow" : false,
    "title" : "DOME (AIO)"
    "tags" : ["templated"]
    "timezone" : "browser"
    "schemaVersion" : 36
    "version" : 1
    "refresh" : ""
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
    }
  })
}
