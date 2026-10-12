locals {
  stop_elastic = <<COMMAND
    set -x
    kubectl --server ${data.vault_generic_secret.k8s_auth_inactive.data.HOST}  \
     --token ${data.vault_generic_secret.k8s_auth_inactive.data.k8s_sa_token}  \
     --insecure-skip-tls-verify=true  \
     scale statefulset -n elastic --replicas=0 --all
    sleep 29
  COMMAND

  rm_pvc_elastic = <<COMMAND
    set -x
    kubectl --server ${data.vault_generic_secret.k8s_auth_inactive.data.HOST}  \
     --token ${data.vault_generic_secret.k8s_auth_inactive.data.k8s_sa_token}  \
     --insecure-skip-tls-verify=true  \
     delete pvc --all -n elastic
    sleep 29
  COMMAND

  rm_pv_elastic = <<COMMAND
    set -x
    kubectl --server ${data.vault_generic_secret.k8s_auth_inactive.data.HOST}  \
     --token ${data.vault_generic_secret.k8s_auth_inactive.data.k8s_sa_token}  \
     --insecure-skip-tls-verify=true  \
     delete pv -l elastic=elasticsearch
    sleep 29
  COMMAND
}


resource "null_resource" "stop_elastic" {

  triggers = {
    command = md5(local.stop_elastic)
  }
  provisioner "local-exec" {
    interpreter = ["/bin/bash", "-c"]
    command     = local.stop_elastic
  }
}

resource "null_resource" "rm_elastic_pvc" {

  triggers = {
    command = md5(local.rm_pvc_elastic)
  }
  provisioner "local-exec" {
    interpreter = ["/bin/bash", "-c"]
    command     = local.rm_pvc_elastic
  }
  depends_on = [ null_resource.stop_elastic ]
}

resource "null_resource" "rm_elastic_pv" {

  triggers = {
    command = md5(local.rm_pv_elastic)
  }
  provisioner "local-exec" {
    interpreter = ["/bin/bash", "-c"]
    command     = local.rm_pv_elastic
  }
  depends_on = [ null_resource.rm_elastic_pvc ]
}
