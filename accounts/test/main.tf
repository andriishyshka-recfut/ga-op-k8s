variable "Settings" {}



module "vpc-bastion" {
  source   = "../../terraform-modules/vpc-bastion"
  Settings = var.Settings
}
