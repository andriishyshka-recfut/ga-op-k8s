# resource "google_service_account" "es_server" {
#   account_id   = "elastic-backup"
#   display_name = "ES Server"
#   lifecycle {
#     prevent_destroy = true
#   }
# }

# variable "EsServiceAccountIamRoles" {
#   type = list(string)
#   default = [
#     "roles/storage.objectAdmin",
#     "roles/storage.admin"
#   ]
#   description = "List of storage bucket roles."
# }
# resource "google_project_iam_member" "es_service_account" {
#   count   = length(var.EsServiceAccountIamRoles)
#   project = data.google_project.current.project_id
#   role    = element(var.EsServiceAccountIamRoles, count.index)
#   member  = "serviceAccount:${google_service_account.es_server.email}"
#   lifecycle {
#     prevent_destroy = true
#   }
# }
