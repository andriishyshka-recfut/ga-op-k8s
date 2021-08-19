locals {
  gkeKmsVolumeKey = var.Settings.clusters[var.Cluster].persistent_resources.gke_kms_volume_key
  gkeRegion           = var.Settings.clusters[var.Cluster].region
}

data "google_kms_key_ring" "key_ring" {
  name     = local.gkeKmsVolumeKey
  location = local.gkeRegion
}

data "google_kms_crypto_key" "crypto_key" {
  name     = local.gkeKmsVolumeKey
  key_ring = data.google_kms_key_ring.key_ring.self_link
}



resource "null_resource" "patch_storage_class" {

  provisioner "local-exec" {
    interpreter = ["/bin/bash", "-c"]
    command     = <<COMMAND
    kubectl patch --server ${local.gkeClusterEndpoint}  \
     --token ${local.gkeBearerToken}  \
     --insecure-skip-tls-verify=true  \
     storageclass standard -p \
     '{"metadata": {"annotations":{"storageclass.kubernetes.io/is-default-class":"false"}}}'
    cat << EOF | kubectl apply --server ${local.gkeClusterEndpoint}  \
     --token ${local.gkeBearerToken}  \
     --insecure-skip-tls-verify=true  -f -

${replace(file("${path.module}/storageclass.yaml"),"KMS_KEY_ID",data.google_kms_crypto_key.crypto_key.id)}

EOF


COMMAND
  }
}
