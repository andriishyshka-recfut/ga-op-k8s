# data "google_container_engine_versions" "version" {
#   location = var.settings[var.cluster].region
# }
#
resource "google_container_cluster" "cluster" {

  provider = google-beta

  name                      = var.cluster
  location                  = var.settings[var.cluster].region
  network                   = data.google_compute_network.vpc.self_link
  subnetwork                = google_compute_subnetwork.net.name
  default_max_pods_per_node = var.settings[var.cluster].pods_per_node
  #min_master_version = data.google_container_engine_versions.version.latest_master_version
  release_channel {
    channel = "RAPID"
  }
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
    preemptible     = true
    tags            = ["${var.cluster}"]
    service_account = google_service_account.gke-sa.unique_id
    oauth_scopes = [
      "https://www.googleapis.com/auth/logging.write",
      "https://www.googleapis.com/auth/monitoring",
    ]
  }

  // Configure the cluster to have private nodes and private control plane access only
  private_cluster_config {
    enable_private_endpoint = "true"
    enable_private_nodes    = "true"
    master_ipv4_cidr_block  = var.settings[var.cluster].master_ipv4_cidr_block
  }

  master_authorized_networks_config {
    cidr_blocks {
      display_name = "bastion"
      cidr_block   = format("%s/32", data.google_compute_instance.bastion.network_interface.0.network_ip)
    }
    # cidr_blocks {
    #   display_name = "infra"
    #   cidr_block   = var.settings["infra"].pods_subnet_range
    # }
  }

  // Allocate IPs in our subnetwork
  ip_allocation_policy {
    cluster_secondary_range_name  = element(google_compute_subnetwork.net.secondary_ip_range, 0).range_name
    services_secondary_range_name = element(google_compute_subnetwork.net.secondary_ip_range, 1).range_name
  }

  network_policy {
    enabled = true
  }
  addons_config {
    network_policy_config {
      disabled = false
    }
    http_load_balancing {
      disabled = true
    }
    horizontal_pod_autoscaling {
      disabled = false
    }
    gce_persistent_disk_csi_driver_config {
      enabled = true
    }
    istio_config {
      disabled = true
      //disabled = false
      //auth = "AUTH_MUTUAL_TLS"
    }
  }

  lifecycle {
    ignore_changes = all
  }
  depends_on = [
    google_compute_subnetwork.net
  ]
}


resource "google_container_node_pool" "cluster_preemptible_nodes" {
  lifecycle {
    ignore_changes = all
  }

  provider = google-beta
  name     = "${var.cluster}-node-pool"
  location = var.settings[var.cluster].region
  cluster  = google_container_cluster.cluster.name
  autoscaling {
    min_node_count = var.settings[var.cluster].min_node_count
    max_node_count = var.settings[var.cluster].max_node_count
  }
  node_count = var.settings[var.cluster].min_node_count
  # version = data.google_container_engine_versions.version.latest_node_version

  node_config {
    preemptible     = true
    machine_type    = var.settings[var.cluster].machine_type
    tags            = ["${var.cluster}"]
    service_account = google_service_account.gke-sa.unique_id

    metadata = {
      disable-legacy-endpoints = "true"
    }


    oauth_scopes = [
      "https://www.googleapis.com/auth/logging.write",
      "https://www.googleapis.com/auth/monitoring",
    ]
  }
  management {
    auto_repair  = "true"
    auto_upgrade = "true"
  }

  timeouts {
    create = "60m"
    update = "20m"
  }
}
