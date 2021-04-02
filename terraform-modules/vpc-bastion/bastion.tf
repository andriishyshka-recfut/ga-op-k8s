
resource "google_compute_address" "envoy" {
  name = "envoy"
  depends_on = [
    google_project_iam_member.service_account
  ]
}

resource "google_compute_address" "wireguard" {
  name = "wireguard"
  depends_on = [
    google_project_iam_member.service_account
  ]
}

resource "google_compute_instance" "bastion" {
  name         = var.Settings.bastion_hostname
  machine_type = "g1-small"
  zone         = var.Settings.bastion_zone
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
    subnetwork = google_compute_subnetwork.envoy.name
    // Add an ephemeral external IP.
    access_config {
      nat_ip = google_compute_address.envoy.address
    }
  }
  network_interface {
    subnetwork = google_compute_subnetwork.wireguard.name
    // Add an ephemeral external IP.
    access_config {
      nat_ip = google_compute_address.wireguard.address
    }
  }
  // Allow the instance to be stopped by terraform when updating configuration
  allow_stopping_for_update = true
  metadata = {
    enable-oslogin = "TRUE"
  }
  metadata_startup_script = <<EOT

  iptables -t mangle -A PREROUTING -m conntrack --ctstate NEW -i ens5 -j CONNMARK --set-mark 0x7
  iptables -t mangle -A PREROUTING --src 172.18.0.0/16 -j CONNMARK --restore-mark
  sysctl net.ipv4.conf.ens5.rp_filter=2
  sysctl net.ipv4.conf.all.rp_filter=2
  ip rule add fwmark 0x7 table 7
  ip route add default via 172.20.0.1 dev ens5 table 7
  ip route add 172.20.0.0/24  dev ens5 table 7

EOT
  provisioner "remote-exec" {
    inline = [
      "echo",
    ]
    connection {
      type = "ssh"
      user = "sa_${data.google_service_account.me.unique_id}"
      //private_key = file("./ssh-key-ansible-sa")
      host = google_compute_address.envoy.address
    }
  }

}


// Upload temp key to be able run ansible

data "external" "data" {
  program = ["sh", "${path.module}/../generate-temp-ssh-key.sh"]
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
output "DnsRecord" {
  value = <<DNS
  Please make sure that this DNS record configured this way:
    ${var.Settings.bastion_dns}    A  ${google_compute_address.wireguard.address}

DNS

}


resource "local_file" "ansible_gcp_inventory" {
  content  = templatefile("${path.module}/../../ansible/inventory.gcp.yml.tmpl", { project = data.google_service_account.me.project })
  filename = "${path.module}/../../ansible/inventory.gcp.yaml"
}
resource "null_resource" "ansible_playbook" {

  triggers = {
    vm_change         = google_compute_instance.bastion.id
    playbook_contents = md5(file("${path.module}/../../ansible/bastion-provision.yml"))
  }

  provisioner "local-exec" {
    command = <<COMMAND

    cd ${path.module}/../../ansible &&\
    ansible-playbook bastion-provision.yml \
      --user sa_${data.google_service_account.me.unique_id} \
      -e 'ansible_python_interpreter=/usr/bin/python3.7' \
      -i ./inventory.gcp.yaml
COMMAND
    environment = {
      CLUSTER_SETTINGS = jsonencode(var.Settings)
      BASTION_DNS      = var.Settings.bastion_dns
    }
  }
  depends_on = [
    google_compute_instance.bastion,
    google_os_login_ssh_public_key.cache,
    local_file.ansible_gcp_inventory
  ]
}
