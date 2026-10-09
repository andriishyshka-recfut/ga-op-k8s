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
        for idx, cidr in concat(
          flatten([
            for ip in try(var.Settings.zscaler.predefined_private_ip_address, []) :
            # predefined_private_ip_address holds already existing Zscaler host IPs; GKE consumes each value as /32 CIDR.
            "${ip}/32"
          ]),
          flatten([
            for _, vm in try(var.Settings.zscaler.instances, {}) :
            # private_ip_address list is the source of truth for Terraform-managed Zscaler host IPs;
            # GKE consumes each value as /32 CIDR.
            [for ip in try(vm.private_ip_address, []) : "${ip}/32"]
          ])
        ) :
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
    dynamic "additional_ip_ranges_config" {
      for_each = local.k8s_additional_subnets
      content {
        subnetwork           = additional_ip_ranges_config.key
        pod_ipv4_range_names = additional_ip_ranges_config.value
      }
    }
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
    # ignore_changes = [node_config[0].tags]
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
#    ignore_changes = all
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

  network_config {
    enable_private_nodes = true
    subnetwork           = google_compute_subnetwork.net.self_link
    pod_range            = "pods-secondary-range"
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
  name              = each.key
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
    for_each = try(each.value.network_config, null) != null ? [each.value.network_config] : []
    content {
      pod_range = lookup(network_config.value, "subnetwork", null) == null ? network_config.value.pod_range : one([
        for range_name, range in lookup(
          var.Settings.additional_subnets[network_config.value.subnetwork],
          "secondary_ip_ranges",
          {}
        ) :
        range_name
        if try(range.color, null) == var.Color
      ])
      enable_private_nodes = true
      subnetwork           = lookup(network_config.value, "subnetwork", null)
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
