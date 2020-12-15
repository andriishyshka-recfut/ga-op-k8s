

resource "null_resource" "ansible_mongod_crd_playbook" {
  triggers = {
    # playbook_contents  = md5(file("${path.module}/certificates.yaml.tmpl"))
  }
  provisioner "local-exec" {
    interpreter = ["/bin/bash", "-c"]
    command     = <<COMMAND
    kubectl apply --server ${local.gkeClusterEndpoint}  \
     --token ${local.gkeBearerToken}  --insecure-skip-tls-verify=true \
     -n mongo-system \
     -f https://raw.githubusercontent.com/percona/percona-server-mongodb-operator/master/deploy/crd.yaml
COMMAND
  }
}
