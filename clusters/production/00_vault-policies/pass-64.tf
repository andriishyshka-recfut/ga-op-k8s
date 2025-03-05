resource "vault_password_policy" "main64" {
  name   = "main64"
  policy = <<EOT
length = 64
rule "charset" {
  charset = "abcdefghijklmnopqrstuvwxyz"
  min-chars = 1
}
rule "charset" {
  charset = "ABCDEFGHIJKLMNOPQRSTUVWXYZ"
  min-chars = 1
}
rule "charset" {
  charset = "0123456789"
  min-chars = 1
}
rule "charset" {
  charset = "-"
  min-chars = 1
}
  EOT
}

resource "vault_password_policy" "strong64" {
  name   = "strong64"
  policy = <<EOT
length = 64
rule "charset" {
  charset = "abcdefghijklmnopqrstuvwxyz"
  min-chars = 2
}
rule "charset" {
  charset = "ABCDEFGHIJKLMNOPQRSTUVWXYZ"
  min-chars = 2
}
rule "charset" {
  charset = "0123456789"
  min-chars = 2
}
rule "charset" {
  charset = "!@#$%^&*-"
  min-chars = 2
}
  EOT
}
