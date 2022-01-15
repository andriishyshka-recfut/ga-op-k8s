data "vault_generic_secret" "k8s_auth_inactive" {
  path = local.inactiveClusterVaultPath
}

resource "null_resource" "stop_flux" {

  provisioner "local-exec" {
    interpreter = ["/bin/bash", "-c"]
    command     = <<COMMAND
    set -x
    kubectl --server ${data.vault_generic_secret.k8s_auth_inactive.data.HOST}  \
     --token ${data.vault_generic_secret.k8s_auth_inactive.data.k8s_sa_token}  \
     --insecure-skip-tls-verify=true  \
     scale deploy -n flux-system --replicas=0 --all
    sleep 30

    kubectl --server ${data.vault_generic_secret.k8s_auth_inactive.data.HOST}  \
     --token ${data.vault_generic_secret.k8s_auth_inactive.data.k8s_sa_token}  \
     --insecure-skip-tls-verify=true  \
     get ns | grep -e dome -e minion | awk '{print $1}' | xargs -n 1 -I{} \
     kubectl --server ${data.vault_generic_secret.k8s_auth_inactive.data.HOST}  \
     --token ${data.vault_generic_secret.k8s_auth_inactive.data.k8s_sa_token}  \
     --insecure-skip-tls-verify=true  \
     scale deploy -n {} --replicas=0 --all
     sleep 30

     kubectl --server ${data.vault_generic_secret.k8s_auth_inactive.data.HOST}  \
      --token ${data.vault_generic_secret.k8s_auth_inactive.data.k8s_sa_token}  \
      --insecure-skip-tls-verify=true  \
      get deploy -n core | grep -v -e NAME -e rfs-redisfailover | awk '{print $1}'
      | xargs -n 1 -I{} \
      kubectl --server ${data.vault_generic_secret.k8s_auth_inactive.data.HOST}  \
      --token ${data.vault_generic_secret.k8s_auth_inactive.data.k8s_sa_token}  \
      --insecure-skip-tls-verify=true  \
      scale deploy -n core --replicas=0 {}


     kubectl --server ${data.vault_generic_secret.k8s_auth_inactive.data.HOST}  \
      --token ${data.vault_generic_secret.k8s_auth_inactive.data.k8s_sa_token}  \
      --insecure-skip-tls-verify=true  \
      get deploy -n maid | grep -v -e NAME -e rfs-redisfailover | awk '{print $1}'
      | xargs -n 1 -I{} \
      kubectl --server ${data.vault_generic_secret.k8s_auth_inactive.data.HOST}  \
      --token ${data.vault_generic_secret.k8s_auth_inactive.data.k8s_sa_token}  \
      --insecure-skip-tls-verify=true  \
      scale deploy -n maid --replicas=0 {}

     kubectl --server ${data.vault_generic_secret.k8s_auth_inactive.data.HOST}  \
     --token ${data.vault_generic_secret.k8s_auth_inactive.data.k8s_sa_token}  \
     --insecure-skip-tls-verify=true  \
     scale deploy -n magescanner --replicas=0 --all
COMMAND
  }
}
