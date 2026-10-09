
# variable "GkeClusterConnectionSettings" {}
variable "Settings" {}
variable "Cluster" {}
variable "Color" {}
variable "GkeClusterConnectionSettings" {}
variable "RepositoryDomain" {}




locals {

  ports = var.Settings.clusters[var.Cluster][var.Color].istio.bastion.ports
  # ansibleEnvs = merge(var.GkeClusterConnectionSettings, {
  #   CLUSTER_SETTINGS        = jsonencode(var.Settings)
  #   CLUSTER                 = var.Cluster
  #   COLOR                   = var.Color
  #   ANSIBLE_STDOUT_CALLBACK = "debug"
  #   BASTION_DNS             = var.Settings.bastion_dns
  # })
  notRed = var.Color == "red" ? 0 : 1

  command = <<COMMAND
    kubectl patch --server='${var.GkeClusterConnectionSettings.HOST}' \
    --token='${var.GkeClusterConnectionSettings.API_KEY}' \
    --insecure-skip-tls-verify=true  \
    configmaps/istio -n istio-system -p \
    '{"data":{"mesh":"defaultConfig:\n  discoveryAddress: istiod.istio-system.svc:15012\n  tracing:\n    zipkin:\n      address: zipkin.istio-system:9411\ndefaultProviders:\n  metrics:\n  - prometheus\nenablePrometheusMerge: true\nrootNamespace: istio-system\ntrustDomain: cluster.local\naccessLogEncoding: JSON"}}'
  COMMAND
}

#     "$(kubectl get configmaps istio -n istio-system -o json |jq .data.mesh|sed 's/.$//'|sed 's/$/\\naccessLogEncoding: JSON"/'|jq -c "{data: {mesh: .}}")"


