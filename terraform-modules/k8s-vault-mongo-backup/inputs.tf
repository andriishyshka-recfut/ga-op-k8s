
data "google_project" "current_project" {
}

locals {
  mongoNs        = "magescanner"
  # mongoNs        = "mongo"
  currentProject = split("/", data.google_project.current_project.id)[1]
}
