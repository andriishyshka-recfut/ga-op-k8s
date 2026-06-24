resource "google_container_cluster" "cluster" {

  provider = google-beta

  deletion_protection       = false
  name                      = "${var.Cluster}-${var.Color}"
  location                  = local.gkeRegion
  network                   = data.google_compute_network.vpc.self_link
  subnetwork                = google_compute_subnetwork.net.name
  default_max_pods_per_node = var.Settings.clusters[var.Cluster].pods_per_node
  #min_master_version = data.google_container_engine_versions.version.latest_master_version
  release_channel {
    channel = "UNSPECIFIED"
  }
  # We can't create a cluster with no node pool defined, but we want to only use
  # separately managed node pools. So we create the smallest possible default
  # node pool and immediately delete it.
  remove_default_node_pool = true
  initial_node_count       = 1

  # master_auth {
  #   username = ""
  #   password = ""
  #
  #   client_certificate_config {
  #     issue_client_certificate = false
  #   }
  # }
  logging_config {
    enable_components = ["SYSTEM_COMPONENTS"]
  }
  node_config {
    preemptible     = local.isPreemptible
    tags            = [var.Cluster]
    service_account = google_service_account.gke_sa.unique_id
    oauth_scopes = [
      "https://www.googleapis.com/auth/logging.write",
      "https://www.googleapis.com/auth/monitoring",
    ]
  }

  // Configure the cluster to have private nodes and private control plane access only
  private_cluster_config {
    enable_private_endpoint = "true"
    enable_private_nodes    = "true"
    master_ipv4_cidr_block  = var.Settings.clusters[var.Cluster][var.Color].master_ipv4_cidr_block
  }

  master_authorized_networks_config {
    cidr_blocks {
      display_name = "bastion"
      cidr_block   = format("%s/32", data.google_compute_instance.bastion.network_interface.0.network_ip)
    }
    dynamic "cidr_blocks" {
      for_each = var.ClusterColors
      content {
        display_name = "${cidr_blocks.value}-pods"
        cidr_block   = var.Settings.clusters[var.Cluster][cidr_blocks.value].subnets.pods_secondary_range
      }
    }

    dynamic "cidr_blocks" {
      for_each = {
        for idx, cidr in lookup(var.Settings, "zscalerIP", []) :
        idx => cidr
      }

      content {
        display_name = "zscaler-${cidr_blocks.key}"
        cidr_block   = cidr_blocks.value
      }
    }
    # cidr_blocks {
    #   display_name = "blue-pods"
    #   cidr_block   = local.bluePods
    # }
    # cidr_blocks {
    #   display_name = "green-pods"
    #   cidr_block   = local.greenPods
    # }
    # cidr_blocks {
    #   display_name = "red-pods"
    #   cidr_block   = local.redPods
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


  monitoring_config {
    managed_prometheus {
      enabled = false
    }
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
    dns_cache_config {
      enabled = true
    }

  }

  authenticator_groups_config {
    security_group = "gke-security-groups@geminiadvisory.io"
  }
  lifecycle {
    ignore_changes = all
  }

  workload_identity_config {
    workload_pool = "${var.Settings.gcpProject}.svc.id.goog"
  }

  depends_on = [
    google_compute_subnetwork.net
  ]
}


resource "google_container_node_pool" "nodepool_default" {
  lifecycle {
    ignore_changes = all
  }

  provider = google-beta
  name     = "default"
  location = local.gkeRegion
  cluster  = google_container_cluster.cluster.name
  autoscaling {
    min_node_count  = 1
    max_node_count  = 7
    location_policy = "BALANCED"
  }
  node_count = 1
  # version = data.google_container_engine_versions.version.latest_node_version

  node_config {
    preemptible = local.isPreemptible

    machine_type    = local.defaultMachineType
    tags            = [var.Cluster, "${var.Cluster}-${var.Color}"]
    service_account = google_service_account.gke_sa.unique_id

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
    auto_upgrade = "false"
  }

  timeouts {
    create = "60m"
    update = "20m"
  }
}

resource "google_container_node_pool" "nodepool_additional" {
  for_each = local.additionalNodepools
  lifecycle {
    ignore_changes = all
  }

  provider          = google-beta
  name              = "${each.key}"
  location          = local.gkeRegion
  cluster           = google_container_cluster.cluster.name
  max_pods_per_node = lookup(each.value, "maxPodsPerNode", var.Settings.clusters[var.Cluster].pods_per_node)

  autoscaling {
    min_node_count = each.value.minNodes
    max_node_count = each.value.maxNodes
  }
  node_count = each.value.minNodes

  node_config {
    preemptible     = each.value.preemptible
    machine_type    = each.value.machineType
    tags            = [var.Cluster, "${var.Cluster}-${var.Color}", "${var.Cluster}-${var.Color}-${each.key}"]
    service_account = google_service_account.gke_sa.unique_id
    metadata = {
      disable-legacy-endpoints = "true"
    }
    oauth_scopes = [
      "https://www.googleapis.com/auth/logging.write",
      "https://www.googleapis.com/auth/monitoring",
    ]
    labels = {
      "workloadsType" = each.value.taintWorkloadsType
    }
    taint {
      key    = "workloadsType"
      value  = each.value.taintWorkloadsType
      effect = "NO_SCHEDULE"
    }
  }
  dynamic "network_config" {
    for_each = lookup(each.value, "pod_ip_subnetwork_name", false) != false ? [0] : []
    content {
      pod_range            = local.additionalNodepools[each.key].pod_ip_subnetwork_name
      enable_private_nodes = true
      # additional_pod_network_configs {
      #   subnetwork          = "${var.Cluster}-${var.Color}-subnetwork"
      #   secondary_pod_range = local.additionalNodepools[each.key].pod_ip_subnetwork_name
      #   max_pods_per_node   = each.value.maxPodsPerNode
      # }
    }
  }
  management {
    auto_repair  = "true"
    auto_upgrade = "false"
  }

  timeouts {
    create = "60m"
    update = "20m"
  }
}
