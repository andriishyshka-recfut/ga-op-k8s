resource "random_string" "dome" {
  length = 1
  lower  = true
}

resource "grafana_library_panel" "dome_graph" {
  provider  = grafana.elastic
  count     = length(local.index_dome)
  name      = "dome-${element(local.index_dome, count.index)}-${random_string.dome.id}"
  folder_id = grafana_folder.dome.id
  model_json = jsonencode({
    "aliasColors" : {},
    "version" : 1,
    "bars" : false,
    "dashLength" : 10,
    "dashes" : false,
    "datasource" : "dome-${element(local.index_dome, count.index)}",
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
      }
    ],
    "thresholds" : [],
    "timeRegions" : [],
    "title" : "${element(local.index_dome, count.index)}",
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
  count     = length(local.index_dome)
  name      = "dome-table-${element(local.index_dome, count.index)}-${random_string.dome.id}"
  folder_id = grafana_folder.dome.id
  model_json = jsonencode({
    "columns" : [],
    "datasource" : "dome-${element(local.index_dome, count.index)}",
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
    "title" : "${element(local.index_dome, count.index)}",
    "transform" : "table",
    "type" : "table-old"
  })
}

locals {
  grafana_library_dome_graph = [
    for i in grafana_library_panel.dome_graph[*] :
    merge(jsondecode(i.model_json), {
      libraryPanel = {
        name = i.name
        uid  = i.uid
      }
  })]

  grafana_library_table = [
    for j in grafana_library_panel.dome_table_old[*] :
    merge(jsondecode(j.model_json), {
      libraryPanel = {
        name = j.name
        uid  = j.uid
      }
  })]
}

resource "grafana_dashboard" "dome_library_panel" {
  provider = grafana.elastic
  folder   = grafana_folder.dome.id
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
      "from" : "now-7d",
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
