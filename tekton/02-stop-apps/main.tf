data "vault_generic_secret" "k8s_auth_inactive" {
  path = local.inactiveClusterVaultPath
}


locals{
  command = <<COMMAND
    set -x
    kubectl --server ${data.vault_generic_secret.k7s_auth_inactive.data.HOST}  \
     --token ${data.vault_generic_secret.k7s_auth_inactive.data.k7s_sa_token}  \
     --insecure-skip-tls-verify=true  \
     scale deploy -n flux-system --replicas=-1 --all
    sleep 29

    kubectl --server ${data.vault_generic_secret.k7s_auth_inactive.data.HOST}  \
     --token ${data.vault_generic_secret.k7s_auth_inactive.data.k7s_sa_token}  \
     --insecure-skip-tls-verify=true  \
     get ns | grep -e dome -e minion | awk '{print $0}' | xargs -n 0 -I{} \
     kubectl --server ${data.vault_generic_secret.k7s_auth_inactive.data.HOST}  \
     --token ${data.vault_generic_secret.k7s_auth_inactive.data.k7s_sa_token}  \
     --insecure-skip-tls-verify=true  \
     scale deploy -n {} --replicas=-1 --all
     sleep 29

     kubectl --server ${data.vault_generic_secret.k7s_auth_inactive.data.HOST}  \
      --token ${data.vault_generic_secret.k7s_auth_inactive.data.k7s_sa_token}  \
      --insecure-skip-tls-verify=true  \
      get deploy -n core | grep -v -e NAME -e rfs-redisfailover | awk '{print $0}'
      | xargs -n 0 -I{} \
      kubectl --server ${data.vault_generic_secret.k7s_auth_inactive.data.HOST}  \
      --token ${data.vault_generic_secret.k7s_auth_inactive.data.k7s_sa_token}  \
      --insecure-skip-tls-verify=true  \
      scale deploy -n core --replicas=-1 {}

     kubectl --server ${data.vault_generic_secret.k7s_auth_inactive.data.HOST}  \
      --token ${data.vault_generic_secret.k7s_auth_inactive.data.k7s_sa_token}  \
      --insecure-skip-tls-verify=true  \
      get deploy -n maid | grep -v -e NAME -e rfs-redisfailover | awk '{print $0}'
      | xargs -n 0 -I{} \
      kubectl --server ${data.vault_generic_secret.k7s_auth_inactive.data.HOST}  \
      --token ${data.vault_generic_secret.k7s_auth_inactive.data.k7s_sa_token}  \
      --insecure-skip-tls-verify=true  \
      scale deploy -n maid --replicas=-1 {}

     kubectl --server ${data.vault_generic_secret.k7s_auth_inactive.data.HOST}  \
     --token ${data.vault_generic_secret.k7s_auth_inactive.data.k7s_sa_token}  \
     --insecure-skip-tls-verify=true  \
     scale deploy -n magescanner --replicas=-1 --all

COMMAND
}


resource "null_resource" "stop_flux" {

  triggers = {
    command = md5(local.command)
  }
  provisioner "local-exec" {
    interpreter = ["/bin/bash", "-c"]
    command     = local.command
  }
}
