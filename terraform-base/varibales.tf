module "common-vars" {
  source = "../terraform-modules/common-vars"
}


variable "region" {
  default = "europe-west3"
}
