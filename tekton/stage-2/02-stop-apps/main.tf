data "vault_generic_secret" "k8s_auth_inactive" {
  path = local.inactiveClusterVaultPath
}


locals {
  stop_flux = <<COMMAND
    set -x
    kubectl --server ${data.vault_generic_secret.k8s_auth_inactive.data.HOST}  \
     --token ${data.vault_generic_secret.k8s_auth_inactive.data.k8s_sa_token}  \
     --insecure-skip-tls-verify=true  \
     scale deploy -n flux-system --replicas=0 --all
    sleep 29
  COMMAND

  stop_zero_services = <<COMMAND
    kubectl --server ${data.vault_generic_secret.k8s_auth_inactive.data.HOST}  \
     --token ${data.vault_generic_secret.k8s_auth_inactive.data.k8s_sa_token}  \
     --insecure-skip-tls-verify=true  \
     get deployment -l zero=true --all-namespaces|awk 'NR>1 {print $1,$2}'| xargs -n 2 \
     kubectl --server ${data.vault_generic_secret.k8s_auth_inactive.data.HOST}  \
     --token ${data.vault_generic_secret.k8s_auth_inactive.data.k8s_sa_token}  \
     --insecure-skip-tls-verify=true  \
     scale deploy --replicas=0 -n $1 && \
    kubectl --server ${data.vault_generic_secret.k8s_auth_inactive.data.HOST}  \
     --token ${data.vault_generic_secret.k8s_auth_inactive.data.k8s_sa_token}  \
     --insecure-skip-tls-verify=true  \
     get statefulset -l zero=true --all-namespaces|awk 'NR>1 {print $1,$2}'| xargs -n 2 \
     kubectl --server ${data.vault_generic_secret.k8s_auth_inactive.data.HOST}  \
     --token ${data.vault_generic_secret.k8s_auth_inactive.data.k8s_sa_token}  \
     --insecure-skip-tls-verify=true  \
     scale statefulset --replicas=0 -n $1
    sleep 29
  COMMAND

  stop_etl_operator = <<COMMAND
    kubectl --server ${data.vault_generic_secret.k8s_auth_inactive.data.HOST}  \
     --token ${data.vault_generic_secret.k8s_auth_inactive.data.k8s_sa_token}  \
     --insecure-skip-tls-verify=true  \
     scale deploy -n etl --replicas=0 --all
  COMMAND

  stop_prometheus_thanos = <<COMMAND
    kubectl --server ${data.vault_generic_secret.k8s_auth_inactive.data.HOST}  \
     --token ${data.vault_generic_secret.k8s_auth_inactive.data.k8s_sa_token}  \
     --insecure-skip-tls-verify=true  \
     get deployment -l app.kubernetes.io/name=thanos -n monitoring |awk 'NR>1 {print $1,$2}'| xargs -n 2 \
     kubectl --server ${data.vault_generic_secret.k8s_auth_inactive.data.HOST}  \
     --token ${data.vault_generic_secret.k8s_auth_inactive.data.k8s_sa_token}  \
     --insecure-skip-tls-verify=true  \
     scale deploy --replicas=0 -n $1 && \
    kubectl --server ${data.vault_generic_secret.k8s_auth_inactive.data.HOST}  \
     --token ${data.vault_generic_secret.k8s_auth_inactive.data.k8s_sa_token}  \
     --insecure-skip-tls-verify=true  \
     get statefulset -l 'app.kubernetes.io/name in (prometheus, thanos, thanos-ruler)' -n monitoring |awk 'NR>1 {print $1,$2}'| xargs -n 2 \
     kubectl --server ${data.vault_generic_secret.k8s_auth_inactive.data.HOST}  \
     --token ${data.vault_generic_secret.k8s_auth_inactive.data.k8s_sa_token}  \
     --insecure-skip-tls-verify=true  \
     scale statefulset --replicas=0 -n $1
    sleep 29
  COMMAND

  delete_zero_cronjobs = <<COMMAND
    kubectl --server ${data.vault_generic_secret.k8s_auth_inactive.data.HOST}  \
     --token ${data.vault_generic_secret.k8s_auth_inactive.data.k8s_sa_token}  \
     --insecure-skip-tls-verify=true  \
     delete cronjobs -l zero=true --all-namespaces
    sleep 29
  COMMAND

  stop_cvat = <<COMMAND
    kubectl --server ${data.vault_generic_secret.k8s_auth_inactive.data.HOST}  \
     --token ${data.vault_generic_secret.k8s_auth_inactive.data.k8s_sa_token}  \
     --insecure-skip-tls-verify=true  \
     scale statefulset -n cvat --replicas=0 --all && \
    kubectl --server ${data.vault_generic_secret.k8s_auth_inactive.data.HOST}  \
     --token ${data.vault_generic_secret.k8s_auth_inactive.data.k8s_sa_token}  \
     --insecure-skip-tls-verify=true  \
     scale deploy -n cvat --replicas=0 --all && \
    kubectl --server ${data.vault_generic_secret.k8s_auth_inactive.data.HOST}  \
     --token ${data.vault_generic_secret.k8s_auth_inactive.data.k8s_sa_token}  \
     --insecure-skip-tls-verify=true  \
     delete pvc cvat-backend-data -n cvat  && \
    kubectl --server ${data.vault_generic_secret.k8s_auth_inactive.data.HOST}  \
     --token ${data.vault_generic_secret.k8s_auth_inactive.data.k8s_sa_token}  \
     --insecure-skip-tls-verify=true  \
     delete pv nfs-pv -n cvat
  COMMAND

  stop_nfs = <<COMMAND
    kubectl --server ${data.vault_generic_secret.k8s_auth_inactive.data.HOST}  \
     --token ${data.vault_generic_secret.k8s_auth_inactive.data.k8s_sa_token}  \
     --insecure-skip-tls-verify=true  \
     scale deploy -n nfs --replicas=0 --all
  COMMAND
}


resource "null_resource" "stop_flux" {

  triggers = {
    command = md5(local.stop_flux)
  }
  provisioner "local-exec" {
    interpreter = ["/bin/bash", "-c"]
    command     = local.stop_flux
  }
}

resource "null_resource" "stop_zero_services" {

  triggers = {
    command = md5(local.stop_zero_services)
  }
  provisioner "local-exec" {
    interpreter = ["/bin/bash", "-c"]
    command     = local.stop_zero_services
  }
  depends_on = [null_resource.stop_flux]
}

resource "null_resource" "stop_prometheus_thanos" {

  triggers = {
    command = md5(local.stop_prometheus_thanos)
  }
  provisioner "local-exec" {
    interpreter = ["/bin/bash", "-c"]
    command     = local.stop_prometheus_thanos
  }
  depends_on = [null_resource.stop_flux]
}

resource "null_resource" "delete_zero_cronjobs" {

  triggers = {
    command = md5(local.delete_zero_cronjobs)
  }
  provisioner "local-exec" {
    interpreter = ["/bin/bash", "-c"]
    command     = local.delete_zero_cronjobs
  }
  depends_on = [null_resource.stop_flux, null_resource.stop_etl_operator]
}

resource "null_resource" "stop_etl_operator" {

  triggers = {
    command = md5(local.stop_etl_operator)
  }
  provisioner "local-exec" {
    interpreter = ["/bin/bash", "-c"]
    command     = local.stop_etl_operator
  }
}

resource "null_resource" "stop_cvat" {
  count = var.Cluster == "sandbox" ? 1 : 0
  triggers = {
    command = md5(local.stop_cvat)
  }
  provisioner "local-exec" {
    interpreter = ["/bin/bash", "-c"]
    command     = local.stop_cvat
  }
  depends_on = [null_resource.stop_flux]
}

resource "null_resource" "stop_nfs" {
  count = var.Cluster == "sandbox" ? 1 : 0
  triggers = {
    command = md5(local.stop_nfs)
  }
  provisioner "local-exec" {
    interpreter = ["/bin/bash", "-c"]
    command     = local.stop_nfs
  }
  depends_on = [null_resource.stop_flux, null_resource.stop_cvat]
}
