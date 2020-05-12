// Upload temp key to be able run ansible

data "external" "data" {
  program = ["sh", "../data.sh"]
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

output "please_run" {
  value = "ansible-playbook ansible/playbook.yml --user  sa_$(jq .client_id $GOOGLE_CREDENTIALS -j) --private-key ./ssh-key-ansible-sa"
}
