resource "null_resource" "rerun_failed_jobs" {
  provisioner "local-exec" {
    interpreter = ["/bin/bash", "-c"]
    command     = <<COMMAND
    set -x
    export JOBS=$(kubectl --server ${local.gkeClusterConnectionSettings.HOST} \
     --token ${local.gkeClusterConnectionSettings.API_KEY}  --insecure-skip-tls-verify=true \
      get jobs.batch -n etl | egrep -v '(1/1|^NAME)' | egrep -v 'manual' awk '{print $1}')
    for CRONJOB_NAME in ${JOBS};do kubectl --server ${local.gkeClusterConnectionSettings.HOST} \
     --token ${local.gkeClusterConnectionSettings.API_KEY}  --insecure-skip-tls-verify=true \
      create job -n etl --from=cronjob/${CRONJOB_NAME%-*} ${CRONJOB_NAME%-*}-rerun-by-tekton-$(date '+%H%M'); done
     
COMMAND
  }
  triggers = {
    always_run = "${timestamp()}"
  }

}
