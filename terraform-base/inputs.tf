module "common-vars" {
  source = "../terraform-modules/common-vars"
}


variable "region" {
  default = "us-east4"
}
