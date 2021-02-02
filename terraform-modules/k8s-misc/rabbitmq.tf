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


resource "null_resource" "kubectl_apply_rabbitmq_operator" {
  triggers = {
    # playbook_contents  = md5(file("${path.module}/certificates.yaml.tmpl"))
  }
  provisioner "local-exec" {
    interpreter = ["/bin/bash", "-c"]
    command     = <<COMMAND
    kubectl apply --server ${local.gkeClusterEndpoint}  \
     --token ${local.gkeBearerToken}  --insecure-skip-tls-verify=true \
     --namespace rabbitmq-system \
     -f https://github.com/rabbitmq/cluster-operator/releases/download/v1.4.0/cluster-operator.yml
COMMAND
  }
  depends_on = [

    kubernetes_namespace.rabbitmq_system
  ]
}
