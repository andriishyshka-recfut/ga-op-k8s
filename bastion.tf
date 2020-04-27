

resource "google_compute_instance" "bastion" {
  name = "bastion"
  machine_type = "g1-small"
  zone = format("%s-a", var.region)
  tags = ["dmz"]

  // Specify the Operating System Family and version.
  boot_disk {
    initialize_params {
      image = "debian-cloud/debian-9"
    }
  }


  // Define a network interface in the correct subnet.
  network_interface {
    subnetwork = google_compute_subnetwork.net.name

    // Add an ephemeral external IP.
    access_config {
      // Ephemeral IP
    }
  }

  // Allow the instance to be stopped by terraform when updating configuration
  allow_stopping_for_update = true

}
