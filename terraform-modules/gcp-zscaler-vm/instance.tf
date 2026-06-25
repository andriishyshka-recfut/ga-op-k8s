// Create a reserved public IP for every Zscaler VM.
resource "google_compute_address" "public" {
  for_each = local.zscaler_instances_effective

  project = local.gcp_project
  name    = "${each.value.name}-${each.key}-vm-public-ip"
  region  = local.region
}

// Reserve the exact nic0 private IP for every Zscaler VM.
resource "google_compute_address" "private" {
  for_each = local.zscaler_instances_effective

  project      = local.gcp_project
  name         = "${each.value.name}-${each.key}-vm-private-ip"
  address      = try(each.value.private_ip_address, null)
  region       = local.region
  subnetwork   = data.google_compute_subnetwork.primary[0].self_link
  address_type = "INTERNAL"
}

resource "google_compute_instance" "vm" {
  for_each = local.zscaler_instances_effective

  depends_on = [
    google_service_account.vm,
    google_service_account_iam_member.self_token_creator,
  ]

  project        = local.gcp_project
  name           = "${each.value.name}-${each.key}-vm"
  machine_type   = each.value.machine_type
  zone           = each.value.zone
  tags           = each.value.tags
  labels         = each.value.labels
  can_ip_forward = each.value.can_ip_forward

  lifecycle {
    precondition {
      condition     = try(each.value.zscaler_image, null) != null && try(each.value.zscaler_image, "") != ""
      error_message = "Each Zscaler VM must define zscaler_image directly or via Settings.zscaler.defaults."
    }
    precondition {
      condition     = try(each.value.private_ip_address, null) != null && try(each.value.private_ip_address, "") != ""
      error_message = "Each Zscaler VM must define private_ip_address for every VM created by count_vm."
    }
  }

  boot_disk {
    initialize_params {
      image = each.value.zscaler_image
      size  = each.value.boot_disk_size_gb
      type  = each.value.boot_disk_type
    }
  }

  scheduling {
    automatic_restart   = each.value.automatic_restart
    on_host_maintenance = each.value.on_host_maintenance
  }

  network_interface {
    network    = data.google_compute_network.vpc[0].self_link
    subnetwork = data.google_compute_subnetwork.primary[0].self_link
    network_ip = google_compute_address.private[each.key].address

    access_config {
      nat_ip = google_compute_address.public[each.key].address
    }
  }

  allow_stopping_for_update = each.value.allow_stopping_for_update
  metadata = merge(
    each.value.enable_oslogin ? { enable-oslogin = "TRUE" } : {},
    { enable-guest-attributes = "TRUE" },
    try(each.value.ssh_key, null) != null ? { ssh-keys = "${each.value.ssh_username}:${try(each.value.ssh_key, null)}" } : {},
    try(each.value.metadata, {}),
  )
  metadata_startup_script = try(each.value.user_data, null) != null ? try(each.value.user_data, null) : (
    try(each.value.startup_script, null) != null ? try(each.value.startup_script, null) : local.generated_runtime_startup_script
  )

  service_account {
    email  = google_service_account.vm.email
    scopes = local.service_account_scopes
  }

  shielded_instance_config {
    enable_secure_boot          = each.value.enable_secure_boot
    enable_vtpm                 = each.value.enable_vtpm
    enable_integrity_monitoring = each.value.enable_integrity_monitoring
  }
}
