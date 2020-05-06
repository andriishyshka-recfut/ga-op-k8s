

resource "google_compute_instance" "bastion" {
  name = module.common-vars.bastion_hostname
  machine_type = "g1-small"
  zone = module.common-vars.bastion_zone
  tags = ["dmz"]
  labels = {
    name = "bastion"
  }

  // Specify the Operating System Family and version.
  boot_disk {
    initialize_params {
      image = "debian-cloud/debian-9"
    }
  }

  scheduling {
    preemptible = true
    automatic_restart = false
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
  metadata = {
    enable-oslogin = "TRUE"
  }

}


// Apload temp key to be able run ansible

data "external" "data" {
  program = ["sh", "./data.sh"]
}

data "google_client_openid_userinfo" "me" {
}



resource "google_os_login_ssh_public_key" "cache" {
  user =  data.google_client_openid_userinfo.me.email
  key = data.external.data.result["pub_certificate"]
  expiration_time_usec = data.external.data.result["expiration_date"]
}

output "expiration_date" {
  value = data.external.data.result["expiration_date"]
}
output "pub_certificate" {
  value = data.external.data.result["pub_certificate"]
}
