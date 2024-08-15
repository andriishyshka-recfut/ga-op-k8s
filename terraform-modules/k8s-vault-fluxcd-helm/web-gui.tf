# resource "random_password" "flux_weave_gui" {
#   length  = 32
#   special = false
# }


# resource "vault_generic_secret" "flux_pass" {
#   path       = "secret/flux/flux-${var.Cluster}-${var.Color}"
#   data_json  = <<EOT
# {
#   "login": "admin",
#   "password": "${random_password.flux_weave_gui.result}"
# }
# EOT
#   depends_on = [random_password.flux_weave_gui]
# }
