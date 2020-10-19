
resource "kubernetes_namespace" "mongo-system" {
  metadata {
    name = "mongo-system"
    # labels = {
    #   istio-injection = "enabled"
    # }
  }
}
resource "null_resource" "ansible_mongod_crd_playbook" {
  triggers = {
    # playbook_contents  = md5(file("${path.module}/certificates.yaml.tmpl"))
  }
  provisioner "local-exec" {
    interpreter = ["/bin/bash", "-c"]
    command     = <<COMMAND
    # wget -O ~/mongo_crd  https://raw.githubusercontent.com/percona/percona-server-mongodb-operator/master/deploy/crd.yaml
    # wget -O ~/mongo_rbac  https://raw.githubusercontent.com/percona/percona-server-mongodb-operator/master/deploy/rbac.yaml &&\
    # wget -O ~/mongo_operator  https://raw.githubusercontent.com/percona/percona-server-mongodb-operator/master/deploy/operator.yaml &&\
    # cat ~/mongo_crd <(echo "---") ~/mongo_rbac <(echo "---") ~/mongo_operator > ~/mongod_crd &&\
    kubectl apply --server ${local.gke_cluster_endpoint}   --token ${local.gke_bearer_token}  --insecure-skip-tls-verify=true -n mongo-system -f https://raw.githubusercontent.com/percona/percona-server-mongodb-operator/master/deploy/crd.yaml
COMMAND
  }
  depends_on = [
    kubernetes_namespace.mongo-system
  ]
}
