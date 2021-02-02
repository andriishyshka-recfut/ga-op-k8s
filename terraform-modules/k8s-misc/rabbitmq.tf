resource "kubernetes_namespace" "rabbitmq_system" {
  metadata {
    name = "rabbitmq-system"
    labels = {
      #   istio-injection = "enabled"
      "app.kubernetes.io/name"      = "rabbitmq-system"
      "app.kubernetes.io/component" = "rabbitmq-cluster-operator"
      "app.kubernetes.io/part-of"   = "rabbitmq"
    }
  }
}
# Steps to install rabbitmq operator require kustomize templating. I don't want to clone operator repo during deployment so I am placing rendered yaml files here.
# Next steps should be performed to update them:
/*
git clone git@github.com:rabbitmq/cluster-operator.git
kubectl apply -f cluster-operator/config/crd/bases/rabbitmq.com_rabbitmqclusters.yaml --dry-run -o yaml > rabbitmq_operator.yaml
echo --- >> rabbitmq_operator.yaml
kubectl apply --kustomize  cluster-operator/config/rbac/ --dry-run -o yaml >> rabbitmq_operator.yaml
echo --- >> rabbitmq_operator.yaml
kubectl apply --kustomize  cluster-operator/config/manager/ --dry-run -o yaml >> rabbitmq_operator.yaml
rm -rf cluster-operator/
*/
resource "null_resource" "ansible_rabbit_crd_install_playbook" {
  triggers = {
    operator = md5(file("${path.module}/rabbitmq_operator.yaml"))
  }
  provisioner "local-exec" {
    command = <<COMMAND
    cd  ${path.module}/../../ansible && \
    ansible-playbook k8s-apply.yml \
    -e 'ansible_python_interpreter=/usr/bin/python3'
COMMAND
    environment = merge(local.ansibleEnvs, {
      k8s_apply_value = "../terraform-modules/k8s-misc/rabbitmq_operator.yaml",
      from_file       = "yes", namespace = "rabbitmq-system"
    })
  }
  depends_on = [
    # google_container_node_pool.cluster_preemptible_nodes,
    kubernetes_namespace.rabbitmq_system
  ]
}
