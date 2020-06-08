
# resource "null_resource" "ansible_vault_playbook" {
#   triggers = {
#     //always_run = "${timestamp()}"
#     // istio_version_change = var.settings.cluster_settings[var.cluster].istio_version
#   }
#   provisioner "local-exec" {
#     command = <<COMMAND
#     cd  ${path.root}/../ansible && \
#     ansible-playbook vault-postinstall.yml \
#       --user  sa_${data.google_service_account.me.unique_id} \
#       -e 'ansible_python_interpreter=/usr/bin/python3' \
#       -i ./inventory.gcp.yaml
# COMMAND
#     environment = {
#     CLUSTER_SETTINGS = jsonencode(var.settings.cluster_settings)
#     CLUSTER = var.cluster
#     ANSIBLE_STDOUT_CALLBACK = "debug"
#     VAULT_ADDR = "https://vault.${var.cluster}.${var.settings.cluster_settings[var.cluster].domain}"
#     }
#   }
#   depends_on = [
#     local_file.ansible_gcp_inventory
#   ]
# }
