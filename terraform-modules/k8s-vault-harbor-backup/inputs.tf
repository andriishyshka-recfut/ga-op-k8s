


data "google_project" "current_project" {
}

locals {
  harborNs       = "harbor"
  currentProject = split("/", data.google_project.current_project.id)[1]
}
