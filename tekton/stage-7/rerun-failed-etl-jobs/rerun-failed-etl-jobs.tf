resource "null_resource" "rerun_failed_jobs" {
  provisioner "local-exec" {
    interpreter = ["/bin/bash", "-c"]
    command     = <<COMMAND
    set -x
    export KCMD=" --server ${local.gkeClusterConnectionSettings.HOST} --token ${local.gkeClusterConnectionSettings.API_KEY} --insecure-skip-tls-verify=true"

    IFS=' '
    read -ra  <<< "$(params.etl_job_name)"
    for ((i=0; i<${#CRONJOB_NAME[@]}; i++)); do
      export RUNNING_POD=$(kubectl $(echo $KCMD) get pod -n etl | egrep 'Running|Pending|Init' | awk '{print $1}' | cut -d'-' -f -6 | grep $CRONJOB_NAME[i])
      [[ $( echo $RUNNING_POD | grep $CRONJOB_NAME[i]) ]] && continue || echo "Current job $CRONJOB_NAME is not running"
      echo "Creating job $CRONJOB_NAME[i]..."
      kubectl $(echo $KCMD) create job -n etl --from=cronjob/$CRONJOB_NAME[i] $CRONJOB_NAME[i]-tekton$(date '+%S')

      if [ $(kubectl $(echo $KCMD) get job -n etl -o jsonpath='{range .items[?(.status.conditions[].type == "Failed")]}{.metadata.name}{"\n"}{end}' | egrep $CRONJOB_NAME[i] | egrep -v 'manual|rerun' | wc -l | xargs ) > 0 ]; then
        kubectl $(echo $KCMD) delete job -n etl $(kubectl $(echo $KCMD) get jobs.batch -n etl --sort-by=.status.startTime -o jsonpath='{range .items[?(.status.conditions[].type == "Failed")]}{.metadata.name}{"\n"}{end}' | egrep $CRONJOB_NAME[i] | egrep -v 'manual|rerun')
      else
        echo "Only one job $CRONJOB_NAME[i] failed, nothing to delete"
      fi
    done
COMMAND
  }
  triggers = {
    always_run = "${timestamp()}"
  }

}
