
data "google_project" "current" {}

locals {
  devRoles = toset( [
    "roles/container.clusterViewer",
    "roles/container.viewer"
  ] )
}

resource "google_project_iam_member" "project" {
  for_each = local.devRoles
  project = data.google_project.current.project_id
  role    = each.key
  member  = "group:dev@geminiadvisory.io"
}
