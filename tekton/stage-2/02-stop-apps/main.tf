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

  stop_dome_and_minion_bots = <<COMMAND
    kubectl --server ${data.vault_generic_secret.k8s_auth_inactive.data.HOST}  \
     --token ${data.vault_generic_secret.k8s_auth_inactive.data.k8s_sa_token}  \
     --insecure-skip-tls-verify=true  \
     get ns | grep -e dome -e minion | awk '{print $1}' | xargs -n 1 -I{} \
     kubectl --server ${data.vault_generic_secret.k8s_auth_inactive.data.HOST}  \
     --token ${data.vault_generic_secret.k8s_auth_inactive.data.k8s_sa_token}  \
     --insecure-skip-tls-verify=true  \
     scale deploy -n {} --replicas=0 --all
     sleep 29
    COMMAND

  stop_core_services = <<COMMAND
     kubectl --server ${data.vault_generic_secret.k8s_auth_inactive.data.HOST}  \
      --token ${data.vault_generic_secret.k8s_auth_inactive.data.k8s_sa_token}  \
      --insecure-skip-tls-verify=true  \
      get deploy -n core | grep -v -e NAME -e rfs-redisfailover | awk '{print $1}'\
      | xargs -n 1 -I{} \
      kubectl --server ${data.vault_generic_secret.k8s_auth_inactive.data.HOST}  \
      --token ${data.vault_generic_secret.k8s_auth_inactive.data.k8s_sa_token}  \
      --insecure-skip-tls-verify=true  \
      scale deploy -n core --replicas=0 {}
  COMMAND


  stop_etl_operator = <<COMMAND
    kubectl --server ${data.vault_generic_secret.k8s_auth_inactive.data.HOST}  \
     --token ${data.vault_generic_secret.k8s_auth_inactive.data.k8s_sa_token}  \
     --insecure-skip-tls-verify=true  \
     scale deploy -n etl --replicas=0 --all
COMMAND

  delete_etl_jobs = <<COMMAND
    kubectl --server ${data.vault_generic_secret.k8s_auth_inactive.data.HOST}  \
      --token ${data.vault_generic_secret.k8s_auth_inactive.data.k8s_sa_token}  \
      --insecure-skip-tls-verify=true  \
      delete cronjobs `kubectl --server ${data.vault_generic_secret.k8s_auth_inactive.data.HOST}  \
      --token ${data.vault_generic_secret.k8s_auth_inactive.data.k8s_sa_token}  \
      --insecure-skip-tls-verify=true  \
      get cronjobs -o custom-columns=:.metadata.name -n etl` -n etl
COMMAND

  stop_maid_services = <<COMMAND
     kubectl --server ${data.vault_generic_secret.k8s_auth_inactive.data.HOST}  \
      --token ${data.vault_generic_secret.k8s_auth_inactive.data.k8s_sa_token}  \
      --insecure-skip-tls-verify=true  \
      get deploy -n maid | grep -v -e NAME -e rfs-redisfailover | awk '{print $1}' \
      | xargs -n 1 -I{} \
      kubectl --server ${data.vault_generic_secret.k8s_auth_inactive.data.HOST}  \
      --token ${data.vault_generic_secret.k8s_auth_inactive.data.k8s_sa_token}  \
      --insecure-skip-tls-verify=true  \
      scale deploy -n maid --replicas=0 {}
COMMAND

  stop_magescanner = <<COMMAND
     kubectl --server ${data.vault_generic_secret.k8s_auth_inactive.data.HOST}  \
     --token ${data.vault_generic_secret.k8s_auth_inactive.data.k8s_sa_token}  \
     --insecure-skip-tls-verify=true  \
     scale deploy -n magescanner --replicas=0 --all
COMMAND

  stop_shout = <<COMMAND
    kubectl --server ${data.vault_generic_secret.k8s_auth_inactive.data.HOST}  \
     --token ${data.vault_generic_secret.k8s_auth_inactive.data.k8s_sa_token}  \
     --insecure-skip-tls-verify=true  \
     scale deploy -n shout --replicas=0 --all
COMMAND

  stop_telegram_services = <<COMMAND
    kubectl --server ${data.vault_generic_secret.k8s_auth_inactive.data.HOST}  \
     --token ${data.vault_generic_secret.k8s_auth_inactive.data.k8s_sa_token}  \
     --insecure-skip-tls-verify=true  \
     scale deploy -n telegram --replicas=0 --all
COMMAND

  stop_pi_services = <<COMMAND
    kubectl --server ${data.vault_generic_secret.k8s_auth_inactive.data.HOST}  \
     --token ${data.vault_generic_secret.k8s_auth_inactive.data.k8s_sa_token}  \
     --insecure-skip-tls-verify=true  \
     scale deploy -n pi --replicas=0 --all
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

# resource "null_resource" "stop_dome_and_minion_bots" {

#   triggers = {
#     command = md5(local.stop_dome_and_minion_bots)
#   }
#   provisioner "local-exec" {
#     interpreter = ["/bin/bash", "-c"]
#     command     = local.stop_dome_and_minion_bots
#   }
#   depends_on = [null_resource.stop_zero_services]
# }

# resource "null_resource" "stop_core_services" {

#   triggers = {
#     command = md5(local.stop_core_services)
#   }
#   provisioner "local-exec" {
#     interpreter = ["/bin/bash", "-c"]
#     command     = local.stop_core_services
#   }
#   depends_on = [null_resource.stop_zero_services]
# }

resource "null_resource" "stop_etl_operator" {

  triggers = {
    command = md5(local.stop_etl_operator)
  }
  provisioner "local-exec" {
    interpreter = ["/bin/bash", "-c"]
    command     = local.stop_etl_operator
  }
}

resource "null_resource" "delete_etl_jobs" {

  triggers = {
    command = md5(local.delete_etl_jobs)
  }
  provisioner "local-exec" {
    interpreter = ["/bin/bash", "-c"]
    command     = local.delete_etl_jobs
  }
  depends_on = [ 
    null_resource.stop_etl_operator 
  ]
}

# resource "null_resource" "stop_maid_services" {

#   triggers = {
#     command = md5(local.stop_maid_services)
#   }
#   provisioner "local-exec" {
#     interpreter = ["/bin/bash", "-c"]
#     command     = local.stop_maid_services
#   }
#   depends_on = [null_resource.stop_zero_services]
# }

# resource "null_resource" "stop_magescanner" {

#   triggers = {
#     command = md5(local.stop_magescanner)
#   }
#   provisioner "local-exec" {
#     interpreter = ["/bin/bash", "-c"]
#     command     = local.stop_magescanner
#   }
#   depends_on = [null_resource.stop_zero_services]
# }


# resource "null_resource" "stop_shout" {

#   triggers = {
#     command = md5(local.stop_shout)
#   }
#   provisioner "local-exec" {
#     interpreter = ["/bin/bash", "-c"]
#     command     = local.stop_shout
#   }
#   depends_on = [null_resource.stop_zero_services]
# }

# resource "null_resource" "stop_telegram_services" {

#   triggers = {
#     command = md5(local.stop_telegram_services)
#   }
#   provisioner "local-exec" {
#     interpreter = ["/bin/bash", "-c"]
#     command     = local.stop_telegram_services
#   }
#   depends_on = [null_resource.stop_zero_services]
# }

# resource "null_resource" "stop_pi_services" {

#   triggers = {
#     command = md5(local.stop_pi_services)
#   }
#   provisioner "local-exec" {
#     interpreter = ["/bin/bash", "-c"]
#     command     = local.stop_pi_services
#   }
#   depends_on = [null_resource.stop_zero_services]
# }

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
  depends_on = [null_resource.stop_flux]
}
