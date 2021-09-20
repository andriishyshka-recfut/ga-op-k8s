resource "kubernetes_namespace" "elastic_operator_ns" {
  metadata {
    name = "elastic-system"
    labels = {
      istio-injection = "enabled"
    }
  }
}



resource "null_resource" "ansible_eck_crd_playbook" {
  triggers = {
    # playbook_contents  = md5(file("${path.module}/certificates.yaml.tmpl"))
    version = local.eckVersion
  }

  provisioner "local-exec" {
    command = <<COMMAND
    set -x
    kubectl create --server ${local.gkeClusterEndpoint}  \
     --token ${local.gkeBearerToken}  \
     --insecure-skip-tls-verify=true  \
     -f https://download.elastic.co/downloads/eck/${local.eckVersion}/crds.yaml
    sleep 10
    kubectl apply --server ${local.gkeClusterEndpoint}  \
     --token ${local.gkeBearerToken}  \
     --insecure-skip-tls-verify=true  \
     -f https://download.elastic.co/downloads/eck/${local.eckVersion}/operator.yaml

COMMAND
    }
  depends_on = [
    # google_container_node_pool.cluster_preemptible_nodes,
    kubernetes_namespace.elastic_operator_ns
  ]
}
