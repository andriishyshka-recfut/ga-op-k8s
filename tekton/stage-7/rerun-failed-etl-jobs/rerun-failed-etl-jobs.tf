resource "null_resource" "rerun_failed_jobs" {
  provisioner "local-exec" {
    interpreter = ["/bin/bash", "-c"]
    command     = <<COMMAND
    set -x
    export KCMD=" --server ${local.gkeClusterConnectionSettings.HOST} --token ${local.gkeClusterConnectionSettings.API_KEY} --insecure-skip-tls-verify=true"
    export CPP_JOB_LIST=$(kubectl $(echo $KCMD) get jobs.batch -n etl -o jsonpath='{range .items[?(.status.conditions[].type == "Failed")]}{.metadata.name}{"\n"}{end}' \
    | egrep 'etl-cpp|gs2s3-cpp' | cut -d'-' -f -5)
    export OTHER_JOB_LIST=$(kubectl $(echo $KCMD) get jobs.batch -n etl -o jsonpath='{range .items[?(.status.conditions[].type == "Failed")]}{.metadata.name}{"\n"}{end}' \
    | egrep -v 'etl-cpp|gs2s3-cpp' | cut -d'-' -f -6)

    export JOB_LIST=$(echo -e "$(echo $OTHER_JOB_LIST | tr ' ' '\n' | uniq)\n$(echo $CPP_JOB_LIST | tr ' ' '\n' | uniq)")
    for CRONJOB_NAME in $(echo $JOB_LIST);do
      export RUNNING_POD=$(kubectl $(echo $KCMD) get pod -n etl | egrep 'Running' | awk '{print $1}' | cut -d'-' -f -6 | grep $CRONJOB_NAME)
      [[ $( echo $RUNNING_POD | grep $CRONJOB_NAME) ]] && continue || echo "Current job $CRONJOB_NAME is not running"
      echo "Creating job $CRONJOB_NAME..."
      kubectl $(echo $KCMD) create jobs.batch -n etl --from=cronjob/$CRONJOB_NAME $CRONJOB_NAME-tekton$(date '+%S')
      if [ $( echo $CRONJOB_NAME | egrep 'camino|gs2s3') ]; then
        export ETL_CRONJOB_NAME="etl-$(echo $CRONJOB_NAME | cut -d'-' -f2-)"
        echo "Creating job $ETL_CRONJOB_NAME..."
        sleep 60
        kubectl $(echo $KCMD) create jobs.batch -n etl --from=cronjob/$ETL_CRONJOB_NAME $ETL_CRONJOB_NAME-tekton$(date '+%S')
      else
        echo " $JOB_NAME - is not camino or gs2s3 job skipping additional job creation"
      fi

      kubectl $(echo $KCMD) delete jobs.batch -n etl $(kubectl $(echo $KCMD) get jobs.batch -n etl -o jsonpath='{range .items[?(.status.conditions[].type == "Failed")]}{.metadata.name}{"\n"}{end}' | egrep tekton)

      if [ $(kubectl $(echo $KCMD) get jobs.batch -n etl -o jsonpath='{range .items[?(.status.conditions[].type == "Failed")]}{.metadata.name}{"\n"}{end}' | egrep $CRONJOB_NAME | wc -l ) > 1 ]; then
        kubectl $(echo $KCMD) delete jobs.batch -n etl $(kubectl $(echo $KCMD) get jobs.batch -n etl --sort-by=.status.startTime \
        -o jsonpath='{range .items[?(.status.conditions[].type == "Failed")]}{.metadata.name}{"\n"}{end}' | egrep $CRONJOB_NAME | tac | tail -n+2)
      else
        echo "Only one job $CRONJOB_NAME failed, nothing to delete"
      fi
    done
COMMAND
  }
  triggers = {
    always_run = "${timestamp()}"
  }

}
