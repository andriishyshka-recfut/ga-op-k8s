variable "Settings" {}
variable "Cluster" {}
variable "Color" {}
variable "reindexer_version" {}
variable "reindexer" {}
variable "rebalancer_version" {}
variable "rebalancer" {}

locals {
    namespace = "elastic-scripts"
    elasticsearch_namespace = "elastic"
}
