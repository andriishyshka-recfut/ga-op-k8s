config {
  module = true
  deep_check = false
  force = false
  disabled_by_default = false
}

rule "terraform_naming_convention" {
  enabled = true
  module{
  # lower-case-with-dashes-and-8-numbers
   custom = "^[a-z0-9]+([-][a-z0-9]+)*$" 
  }
 data {
  format = "snake_case"
 }
 resource {
  format = "snake_case"
 }
 locals {
  # camelCase
  custom = "^[a-z]+([a-zA-Z]+)*$"
 }
 variable {
  # PascalCase
  custom = "^[A-Z]+([a-zA-Z]+)*$"
 }
  output { 
  # PascalCase
  custom = "^[A-Z]+([a-zA-Z]+)*$"
 }
}




