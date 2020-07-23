variable "service_account_iam_roles" {
  type = list

  default = [
    "roles/logging.logWriter",
    "roles/monitoring.metricWriter",
    "roles/monitoring.viewer",
    # "roles/container.admin"
  ]
  description = <<-EOF
  List of the default IAM roles to attach to the service account on the
  GKE Nodes.
  EOF
}

resource "google_service_account" "gke-sa" {
  account_id   = "k8s-${var.cluster}-sa"
  display_name = "${var.cluster} GKE Security Service Account "
}

resource "google_project_iam_member" "service-account" {
  count  = length(var.service_account_iam_roles)
  role   = element(var.service_account_iam_roles, count.index)
  member = format("serviceAccount:%s", google_service_account.gke-sa.email)
}

# resource "google_service_account_key" "admin-key" {
#   service_account_id = google_service_account.gke-sa.name
# }
#https://cloud.google.com/kubernetes-engine/docs/concepts/access-control
# access to cluster should be managed with k8s RBAC not IAM
# resource "google_project_iam_member" "cluster-admin" {
#   provider = google-beta
#   member   = format("serviceAccount:%s", google_service_account.gke-sa.email)
#   role     = "roles/container.admin"
#   condition {
#     title       = " ${var.cluster}-kubernetes-admin"
#     description = "Admin access to deploy resources. Key should be added to Vault server automatically"
#     expression  = "resource.type.startsWith('k8s.io') && resource.name.startsWith(\"${google_container_cluster.cluster.id}\")"
#   }
# }
