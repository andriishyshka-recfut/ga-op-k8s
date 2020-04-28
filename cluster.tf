
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
  default_max_pods_per_node = 8
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

  //addons_config {
//
    //// Enable network policy (Calico)
    //network_policy_config {
      //disabled = false
    //}
  //}
  //network_policy {
    //enabled = "true"
  //}
    // Configure the cluster to have private nodes and private control plane access only
  private_cluster_config {
    enable_private_endpoint = "true"
    enable_private_nodes    = "true"
    master_ipv4_cidr_block  = "172.27.0.240/28"
  }

  master_authorized_networks_config {
    cidr_blocks {
      display_name = "bastion"
      cidr_block   = format("%s/32", google_compute_instance.bastion.network_interface.0.network_ip)
    }
  }

  // Allocate IPs in our subnetwork
  ip_allocation_policy {
    cluster_secondary_range_name  = element(google_compute_subnetwork.net.secondary_ip_range,0).range_name
    services_secondary_range_name = element(google_compute_subnetwork.net.secondary_ip_range,1).range_name

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
