resource "null_resource" "rerun_etl_leftovers" {
  provisioner "local-exec" {
    interpreter = ["/bin/bash", "-c"]
    command     = <<COMMAND
    set -x
    export KCMD=" --server ${local.gkeClusterConnectionSettings.HOST} --token ${local.gkeClusterConnectionSettings.API_KEY} --insecure-skip-tls-verify=true"
    
    echo $(params.etl_job_name)

    IFS=" "
    read -ra  <<< "$(params.etl_job_name)"
    for ((i=0; i<${#CRONJOB_NAME[@]}; i++)); do
      echo "Creating job $CRONJOB_NAME[i]..."
      kubectl $(echo $KCMD) create job -n etl --from=cronjob/$CRONJOB_NAME[i] $CRONJOB_NAME[i]-tekton$(date "+%S")
    done
COMMAND
  }
  triggers = {
    always_run = "${timestamp()}"
  }

}
