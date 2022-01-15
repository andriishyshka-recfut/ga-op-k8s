data "vault_generic_secret" "k8s_auth_inactive" {
  path = local.inactiveClusterVaultPath
}

resource "null_resource" "stop_flux" {

  provisioner "local-exec" {
    interpreter = ["/bin/bash", "-c"]
    command     = <<COMMAND
    set -x
    kubectl --server ${data.vault_generic_secret.k8s_auth.data.HOST}  \
     --token ${data.vault_generic_secret.k8s_auth.data.k8s_sa_token}  \
     --insecure-skip-tls-verify=true  \
     scale deploy -n flux-system --replicas=0 --all
    sleep 30

    kubectl --server ${data.vault_generic_secret.k8s_auth.data.HOST}  \
     --token ${data.vault_generic_secret.k8s_auth.data.k8s_sa_token}  \
     --insecure-skip-tls-verify=true  \
     get ns | grep -e dome -e minion | awk '{print $1}' | xargs -n 1 -I{} \
     kubectl --server ${data.vault_generic_secret.k8s_auth.data.HOST}  \
     --token ${data.vault_generic_secret.k8s_auth.data.k8s_sa_token}  \
     --insecure-skip-tls-verify=true  \
     scale deploy -n {} --replicas=0 --all
     sleep 30

    echo "core\n maid\n magescanner" | xargs -n 1 -I{} \
     kubectl --server ${data.vault_generic_secret.k8s_auth.data.HOST}  \
     --token ${data.vault_generic_secret.k8s_auth.data.k8s_sa_token}  \
     --insecure-skip-tls-verify=true  \
     scale deploy -n {} --replicas=0 --all
COMMAND
  }
}
