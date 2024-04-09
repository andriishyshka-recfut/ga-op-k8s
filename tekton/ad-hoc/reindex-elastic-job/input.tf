locals {
  run_prefix = "index_name_2028080401"
  imageTag = "v1.1"

  workDir = "/opt/reindex/${var.Cluster}"

  elasticSecretsPath = "secret/elasticsearch-admin/elastic7-v2"
  elasticCertsPath = "secret/es-creds-compose-prod"
  slackTokenPath = "secret/slack/elastic_reindexer"

  block_kafka_topics = false


  ################
  # Slack channel
  # (uncomment for corresponding index)
  ################


  # For credz or maid indices:
  # or template "maid"
  # use "maid" channel: 
  # slackChannel = "GAK2NPYLV"

  # For minion and pans indices
  # or template "minion"
  # use "_ccr" channel:
  # slackChannel = "C0428HYAFTL"

  # For dome indices
  # or template "dome"
  # use "dome" channel:
  # slackChannel = "GAJC0BVSM"

  # For paste indices
  # or template "paste"
  # use "artifact" channel:
  # slackChannel = "GAKQWBNDU"


  # For sandbox:
  # use "test" channel:
  slackChannel = "G9SR39LV7"


}
