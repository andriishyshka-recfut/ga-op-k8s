data "gitlab_user" "gitlab" {
  username = "dc"
}

resource "gitlab_personal_access_token" "terraform" {
  user_id    = data.gitlab_user.gitlab.user_id
  name       = "terraform-${var.Cluster}-${local.dateNow}"
  expires_at = formatdate("YYYY-MM-DD",timeadd(timestamp(),"720h"))

  scopes = ["read_repository"]
  depends_on = [ data.gitlab_user.gitlab ]
}

resource "null_resource" "read_repository" {
  triggers = {
    always_run = "${timestamp()}"
  }
  provisioner "local-exec" {
    command = "vault kv put secret/misc/gitlab/token/read_repo token=${gitlab_personal_access_token.terraform.token} username=dc"
  }
  depends_on = [
    gitlab_personal_access_token.terraform
  ]
}
