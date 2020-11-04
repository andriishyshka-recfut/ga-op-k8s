
resource "google_compute_address" "static" {
  name = "ipv4-address"
}


resource "google_compute_instance" "bastion" {
  name         = var.settings.bastion_hostname
  machine_type = "g1-small"
  zone         = var.settings.bastion_zone
  tags         = ["dmz"]
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
    preemptible       = false
    automatic_restart = true
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
      type = "ssh"
      user = "sa_${data.google_service_account.me.unique_id}"
      //private_key = file("./ssh-key-ansible-sa")
      host = google_compute_address.static.address
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
  account_id = element(split("@", data.google_client_openid_userinfo.me.email), 0)
}
resource "google_os_login_ssh_public_key" "cache" {
  user                 = data.google_client_openid_userinfo.me.email
  key                  = data.external.data.result["pub_certificate"]
  expiration_time_usec = data.external.data.result["expiration_date"]
}
/*
output "expiration_date" {
  value = data.external.data.result["expiration_date"]
}
output "pub_certificate" {
  value = data.external.data.result["pub_certificate"]
}*/
output "dns_record" {
  value = <<DNS
  Please make sure that this DNS record configured this way:
    ${var.settings.bastion_dns}    A  ${google_compute_address.static.address}

DNS

}


resource "local_file" "ansible_gcp_inventory" {
  content  = templatefile("${path.root}/../ansible/inventory.gcp.yml.tmpl", { project = data.google_service_account.me.project })
  filename = "${path.root}/../ansible/inventory.gcp.yaml"
}
resource "null_resource" "ansible_playbook" {

  triggers = {
    //always_run = "${timestamp()}"
    vm_change         = google_compute_instance.bastion.id
    playbook_contents = md5(file("${path.root}/../ansible/bastion-provision.yml"))
    # upstream_py_contents    = md5(file("${path.root}/../ansible/files/upstream.py"))
    # stream_template_content = md5(file("${path.root}/../ansible/templates/default-stream.conf"))
  }

  provisioner "local-exec" {
    command = <<COMMAND

    cd ../ansible &&\
    ansible-playbook bastion-provision.yml \
      --user sa_${data.google_service_account.me.unique_id} \
      -e 'ansible_python_interpreter=/usr/bin/python3.7' \
      -i ./inventory.gcp.yaml
COMMAND
    environment = {
      CLUSTER_SETTINGS = jsonencode(var.settings)
      BASTION_DNS      = var.settings.bastion_dns
    }
  }
  depends_on = [
    google_compute_instance.bastion,
    google_os_login_ssh_public_key.cache,
    local_file.ansible_gcp_inventory
  ]
}
