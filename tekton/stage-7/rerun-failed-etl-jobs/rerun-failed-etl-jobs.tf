resource "null_resource" "rerun_failed_jobs" {
  provisioner "local-exec" {
    interpreter = ["/bin/bash", "-c"]
    command     = <<COMMAND
    set -x
    export JOB_LIST=$(kubectl --server ${local.gkeClusterConnectionSettings.HOST} \
    --token ${local.gkeClusterConnectionSettings.API_KEY} --insecure-skip-tls-verify=true \
    get jobs.batch -n etl | egrep -v '(1/1|^NAME)' | egrep -v 'manual' | awk '{print $1}')
    for JOB_NAME in $(echo ${JOB_LIST});do
      [[ $( echo ${JOB_NAME} | egrep 'etl-cpp|gs2s3-cpp' ) ]] && export CRONJOB_NAME=$(echo $JOB_NAME | cut -d'-' -f -5) || export CRONJOB_NAME=$(echo $JOB_NAME | cut -d'-' -f -6)
      echo "Creating job ${CRONJOB_NAME}..."
      kubectl --server ${local.gkeClusterConnectionSettings.HOST} --token ${local.gkeClusterConnectionSettings.API_KEY} \
      --insecure-skip-tls-verify=true create job -n etl --from=cronjob/${CRONJOB_NAME} ${CRONJOB_NAME}-rerunbyscript$(date '+H%Hm%M')
      if [ $( echo ${JOB_NAME} | egrep 'camino|gs2s3') ]; then
        export ETL_CRONJOB_NAME="etl-$(echo $CRONJOB_NAME | cut -d'-' -f -1)"
        echo "Creating job ${ETL_CRONJOB_NAME}..."
        sleep 15
        kubectl --server ${local.gkeClusterConnectionSettings.HOST} --token ${local.gkeClusterConnectionSettings.API_KEY} \
        --insecure-skip-tls-verify=true create job -n etl --from=cronjob/${ETL_CRONJOB_NAME} ${ETL_CRONJOB_NAME}-rerunbyscript$(date '+H%Hm%M')
      else
        echo " ${JOB_NAME} - is not camino or gs2s3 job skipping additional job creation"
      fi
    done
COMMAND
  }
  triggers = {
    always_run = "${timestamp()}"
  }

}
