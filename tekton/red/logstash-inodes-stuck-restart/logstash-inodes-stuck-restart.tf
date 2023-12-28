resource "null_resource" "rerun_failed_jobs" {
  provisioner "local-exec" {
    interpreter = ["/bin/bash", "-c"]
    command     = <<COMMAND
    set -x
    export KCMD=" --server ${local.gkeClusterConnectionSettings.HOST} --token ${local.gkeClusterConnectionSettings.API_KEY} --insecure-skip-tls-verify=true"

    export MINUTES="$(date '+%M')"
    if [ "${MINUTES}" < "55" ]; then
      echo "Restarting logstash..."
      kubectl $(echo $KCMD) rollout restart statefulset -n elastic logstash-red
    elif [ "${MINUTES}" < "45" ]; then
      echo "Waiting for 45 minutes..."
      sleep 180
      echo "Restarting logstash..."
      kubectl $(echo $KCMD) rollout restart statefulset -n elastic logstash-red
    else
      echo "Time is not between 45 and 55 minutes skipping for now"
    fi
COMMAND
  }
  triggers = {
    always_run = "${timestamp()}"
  }

}
