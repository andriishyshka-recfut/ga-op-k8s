
# resource "null_resource" "ansible_vault_k8s_auth" {

#   triggers = {
#     playbook_contents = md5(file("${path.module}/../../ansible/vault-k8s-auth.yml"))
#   }
#   provisioner "local-exec" {
#     command = <<COMMAND
#     cd  ${path.module}/../../ansible && \
#     ansible-playbook vault-k8s-auth.yml \
#       -e 'ansible_python_interpreter=/usr/bin/python3'
# COMMAND
#     environment = merge(local.ansibleEnvs, {
#       kubernetes_host    = local.gkeClusterEndpoint
#       kubernetes_ca_cert = lookup(data.kubernetes_secret.vault.data, "ca.crt")
#       token_reviewer_jwt = lookup(data.kubernetes_secret.vault.data, "token")
#       k8s_sa_token       = lookup(data.kubernetes_secret.cluster_admin_creds.data, "token")
#       k8s_sa_ca_cert     = lookup(data.kubernetes_secret.cluster_admin_creds.data, "ca.crt")
#     })
#   }
#   depends_on = [
#     null_resource.ansible_initial_provisioning_vault_playbook
#   ]
# }
