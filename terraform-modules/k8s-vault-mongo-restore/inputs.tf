
variable "BackupSettings" { }
variable "Cluster" {}
variable "Color" {}


variable "MongoNs" {}
variable "BackupBucket" { }

locals {
  restore_date = "20240417"
}