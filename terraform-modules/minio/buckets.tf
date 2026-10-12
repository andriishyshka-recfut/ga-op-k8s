resource "minio_ilm_tier" "tier" {
  for_each = local.bucketsMap
  bucket   = lookup(each.value, "gcs_bucket_name", each.key)
  name     = lookup(each.value, "gcs_tier_name", "GCS_${upper(each.key)}_TIER")
  endpoint = "https://storage.googleapis.com/"
  type     = "gcs"
  force_new_credentials = true
  gcs_config {
    credentials = data.vault_generic_secret.minio_sa.data.token
  }
  lifecycle {
    ignore_changes = [
      gcs_config[0].credentials
    ]
  }
}

resource "minio_ilm_policy" "comprehensive-rules" {
  for_each = local.bucketsMap
  bucket   = minio_s3_bucket.bucket[each.key].id
  # Rule with transition and expiration
  rule {
    id     = each.key
    status = "Enabled"
    transition {
      days          = "0d"
      storage_class = minio_ilm_tier.tier[each.key].name
    }
  }
  dynamic "rule" {
    for_each = lookup(each.value, "expiration", [])
    content {
      id     = "default_expiration"
      status = "Enabled"
      expiration = rule.value
    }
  }
    dynamic "rule" {
    for_each = lookup(each.value, "custom_expiration", [])
    content {
      id     = "expiration-${rule.value}"
      status = "Enabled"
      expiration = rule.value
      tags = {
        expiration = rule.value
      }
    }
  }
  lifecycle {
    ignore_changes = [
      rule[0].transition[0].days
    ]
  }
  depends_on = [minio_s3_bucket.bucket, minio_ilm_tier.tier]
}

resource "minio_s3_bucket" "bucket" {
  for_each = local.bucketsMap
  bucket   = each.key
}
