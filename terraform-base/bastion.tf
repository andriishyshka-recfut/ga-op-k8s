
resource "google_compute_address" "static" {
  name = "ipv4-address"
}




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
      image = "debian-cloud/debian-10"
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
      nat_ip = google_compute_address.static.address
    }
  }

  // Allow the instance to be stopped by terraform when updating configuration
  allow_stopping_for_update = true
  metadata = {
    enable-oslogin = "TRUE"
  }

  provisioner "remote-exec" {
    inline = [
      "echo",
    ]
    connection {
    type     = "ssh"
    user     = "sa_${data.google_service_account.me.unique_id}"
    private_key = file("./ssh-key-ansible-sa")
    host     = google_compute_address.static.address
  }
  }

}


// Upload temp key to be able run ansible

data "external" "data" {
  program = ["sh", "../data.sh"]
}

data "google_client_openid_userinfo" "me" {
}
data "google_service_account" "me" {
  account_id = element(split("@",data.google_client_openid_userinfo.me.email),0)
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
resource "null_resource" "ansible_playbook" {

  triggers = {
    always_run = "${timestamp()}"
  }

  provisioner "local-exec" {
    command = "cd ansible && ansible-playbook playbook.yml --user  sa_$(jq .client_id $GOOGLE_CREDENTIALS -j) --private-key ../ssh-key-ansible-sa"
    environment = {
    CLUSTER_SETTINGS = jsonencode(module.common-vars.cluster_settings)
    }
  }
  depends_on = [
    google_compute_instance.bastion,
    google_os_login_ssh_public_key.cache
  ]
}
