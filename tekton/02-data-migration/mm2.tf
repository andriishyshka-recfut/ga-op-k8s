
resource "null_resource" "patch_mm2_topic_blacklist" {

  provisioner "local-exec" {
    interpreter = ["/bin/bash", "-c"]
    command     = <<COMMAND
    set -e
    kubectl --server ${data.vault_generic_secret.k8s_auth.data.HOST}  \
     --token ${data.vault_generic_secret.k8s_auth.data.k8s_sa_token}  \
     --insecure-skip-tls-verify=true  \
     patch KafkaMirrorMaker2 mm2 -n kafka --type=json -p="[{'op': 'remove', 'path':'/spec/mirrors/0/topicsBlacklistPattern'}]" || true
COMMAND
  }
}
