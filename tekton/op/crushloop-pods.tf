resource "null_resource" "crushloop_pod_delete" {
  provisioner "local-exec" {
    interpreter = ["/bin/bash", "-c"]
    command     = <<COMMAND
    set -x
    kubectl get pods -A -o=custom-columns='NAME:metadata.name, NAMERSPACE:metadata.namespace , STATE:status.containerStatuses[*].state.waiting.reason ' | grep CrashLoopBackOff | awk '{print "-n "$2" "$1}' | xargs --max-args=3   kubectl delete pod
COMMAND
  }

}
