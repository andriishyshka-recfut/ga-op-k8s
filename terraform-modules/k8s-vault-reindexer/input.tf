variable "Settings" {}
variable "Cluster" {}
variable "Color" {}
variable "reindexer_version" {}
variable "reindexer" {}

locals {
    namespace = "reindexer"
    elasticsearch_namespace = "elastic"
}
