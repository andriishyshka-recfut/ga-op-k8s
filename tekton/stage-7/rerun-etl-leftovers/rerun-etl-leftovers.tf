resource "null_resource" "rerun_etl_leftovers" {
  provisioner "local-exec" {
    interpreter = ["/bin/bash", "-c"]
    command     = <<COMMAND
    set -x
    export KCMD=" --server ${local.gkeClusterConnectionSettings.HOST} --token ${local.gkeClusterConnectionSettings.API_KEY} --insecure-skip-tls-verify=true"
    
    IFS=' '
    read -ra  <<< "$(params.job_name)"
    for ((i=0; i<${#CRONJOB_NAME[@]}; i++)); do
      export RUNNING_POD=$(kubectl $(echo $KCMD) get pod -n etl | egrep 'Running|Pending|Init' | awk '{print $1}' | cut -d'-' -f -6 | grep $CRONJOB_NAME[i])
      [[ $( echo $RUNNING_POD | grep $CRONJOB_NAME[i]) ]] && continue || echo "Current job $CRONJOB_NAME is not running"
      echo "Creating job $CRONJOB_NAME[i]..."
      kubectl $(echo $KCMD) create job -n etl --from=cronjob/$CRONJOB_NAME[i] $CRONJOB_NAME[i]-tekton$(date '+%S')
    done
COMMAND
  }
  triggers = {
    always_run = "${timestamp()}"
  }

}
