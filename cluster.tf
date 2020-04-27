
//resource "google_project_service" "cloudresourcemanager" {
  //service =  "cloudresourcemanager.googleapis.com"
//}
//
//resource "google_project_service" "container" {
  //service =  "container.googleapis.com"
//}


resource "google_container_cluster" "infra" {
  name     = "infra"
  location = var.region
  network = google_compute_network.vpc.self_link
  subnetwork = google_compute_subnetwork.net.name

  # We can't create a cluster with no node pool defined, but we want to only use
  # separately managed node pools. So we create the smallest possible default
  # node pool and immediately delete it.
  remove_default_node_pool = true
  initial_node_count       = 1

  master_auth {
    username = ""
    password = ""

    client_certificate_config {
      issue_client_certificate = false
    }
  }
  node_config {
    tags = ["infra"]
    service_account = google_service_account.gke-sa.unique_id
  }

}


resource "google_container_node_pool" "infra_preemptible_nodes" {
  name       = "infra-node-pool"
  location   = var.region
  cluster    = google_container_cluster.infra.name
  node_count = 3

  node_config {
    preemptible  = true
    machine_type = "n1-standard-1"

    metadata = {
      disable-legacy-endpoints = "true"
    }

    oauth_scopes = [
      "https://www.googleapis.com/auth/logging.write",
      "https://www.googleapis.com/auth/monitoring",
    ]
  }
}
