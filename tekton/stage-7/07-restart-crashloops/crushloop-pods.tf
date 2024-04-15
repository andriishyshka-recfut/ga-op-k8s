resource "null_resource" "crushloop_pod_delete" {
  provisioner "local-exec" {
    interpreter = ["/bin/bash", "-c"]
    command     = <<COMMAND
    set -x
    export KCMD=" --server ${local.gkeClusterConnectionSettings.HOST} --token ${local.gkeClusterConnectionSettings.API_KEY} --insecure-skip-tls-verify=true"
     [[ $(kubectl $(echo $KCMD) get pods -A -o=custom-columns='STATE:status.containerStatuses[*].state.waiting.reason' | egrep CrashLoopBackOff) ]] && \
      kubectl $(echo $KCMD) delete po $(kubectl $(echo $KCMD) get pods -A -o=custom-columns='NAME:metadata.name, NAMERSPACE:metadata.namespace , STATE:status.containerStatuses[*].state.waiting.reason ' \
       | grep CrashLoopBackOff | awk '{print "-n "$2" "$1}') || echo "There is no CrashLoopBackOff pods to delete"
     [[ $(kubectl $(echo $KCMD) get pods -A -o=custom-columns='STATE:status.phase, STATE:status.reason' | grep Failed | egrep -v '<none>') ]] && \
      kubectl $(echo $KCMD) delete po $(kubectl $(echo $KCMD) get pods -A -o=custom-columns='NAME:metadata.name, NAMERSPACE:metadata.namespace, STATE:status.phase, STATE:status.reason' | grep Failed | egrep -v '<none>' \
       | grep CrashLoopBackOff | awk '{print "-n "$2" "$1}') || echo "There is no Failed pods to delete"
COMMAND
  }
  triggers = {
    always_run = "${timestamp()}"
  }

}
