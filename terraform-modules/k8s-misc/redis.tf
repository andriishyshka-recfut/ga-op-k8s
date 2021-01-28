
resource "kubernetes_namespace" "redis_operator_ns" {
  metadata {
    name = "redis-operator-ns"
    # labels = {
    #   istio-injection = "enabled"
    # }
  }
}


resource "null_resource" "ansible_redis_crd_playbook" {
  provisioner "local-exec" {
    command = <<COMMAND
    wget -O ~/redis_crd https://raw.githubusercontent.com/spotahome/redis-operator/master/example/operator/all-redis-operator-resources.yaml &&\
    sed -i "s/namespace: default/namespace: $namespace/" ~/redis_crd &&\
    cd  ${path.module}/../../ansible && \
    ansible-playbook k8s-apply.yml \
    -e 'ansible_python_interpreter=/usr/bin/python3'
COMMAND
    environment = merge(local.ansibleEnvs, {
      k8s_apply_value = "~/redis_crd",
      from_file       = "yes",
      namespace       = "redis-operator-ns"
    })

  }
  depends_on = [
    kubernetes_namespace.redis_operator_ns
  ]
}
