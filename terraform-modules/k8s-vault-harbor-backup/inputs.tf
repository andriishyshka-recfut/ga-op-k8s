locals {
  harborNs = "harbor"
  accessKey = jsondecode(data.vault_generic_secret.minio_auth.data["backup"]).accessKey
  secretKey = jsondecode(data.vault_generic_secret.minio_auth.data["backup"]).secretKey  
}
