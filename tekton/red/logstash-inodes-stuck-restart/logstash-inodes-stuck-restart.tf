resource "null_resource" "rerun_failed_jobs" {
  provisioner "local-exec" {
    interpreter = ["/bin/bash", "-c"]
    command     = <<COMMAND
    set -x
      kubectl --server ${local.gkeClusterConnectionSettings.HOST} --token ${local.gkeClusterConnectionSettings.API_KEY} \
       --insecure-skip-tls-verify=true $(echo $KCMD) rollout restart statefulset -n elastic logstash-red
COMMAND
  }
  triggers = {
    always_run = "${timestamp()}"
  }

}
