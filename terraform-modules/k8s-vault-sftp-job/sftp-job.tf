locals {
  sftpCronJobValues = yamldecode(file("${path.module}/sftp-job/values.yaml"))
}

resource "helm_release" "sftp-job" {
  for_each     = var.job_list
  name         = "sftp-job-${each.key}"
  chart        = "${path.module}/sftp-job"
  wait         = true
  atomic       = true
  namespace    = try(each.value.namespace, local.namespace)
  reset_values = true

  values       = [
         yamlencode(local.sftpCronJobValues)
  ]
  set {
    name       = "config.pipelineName"
    value      = each.key
  }
  set  {
    name       = "name"
    value      = "cronjob-${each.key}"
  }
  set  {
    name       = "namespace"
    value      = try(each.value.namespace, local.namespace)
  }
  set {
    name       = "cronSchedule"
    value      = try(each.value.cron, local.cron)
  }
  set {
    name       = "config.bucketName"
    value      = try(each.value.bucket, local.bucket)
  }
  set {
    name       = "config.bucketUrl"
    value      = try(each.value.minio_url, local.minio_url)
  }
  set {
    name       = "config.minioUser"
    value      = try(each.value.minio_user, local.minio_user)
  }
  set {
    name       = "config.sftp"
    value      = try(each.value.sftp, local.sftp)
  }
  set {
    name       = "config.s3"
    value      = try(each.value.s3, local.s3)
  }
  set {
    name       = "config.email"
    value      = try(each.value.email, local.email)
  }
  set {
    name       = "sshConfig.hostName"
    value      = try(each.value.sftp_host, local.sftp_host)
  }
  set {
    name       = "sshConfig.user"
    value      = try(each.value.sftp_user, each.key)
  }
  set {
    name       = "sshConfig.port"
    value      = try(each.value.sftp_port, local.sftp_port)
  }
  set {
    name       = "config.remoteDestination"
    value      = try(each.value.sftp_destination, local.sftp_destination)
  }
  set {
    name       = "sshConfig.sftpOptions"
    value      = try(each.value.sftp_options, local.sftp_options)
  }
  set {
    name       = "emailConfig.subject"
    value      = try(each.value.email_subject, local.email_subject)
  }
  set {
    name       = "rescueNotify.emailSubject"
    value      = try(each.value.rescue_email_subject, local.rescue_email_subject)
  }
  set {
    name       = "awsS3.bucket"
    value      = try(each.value.aws_s3_bucket, local.aws_s3_bucket)
  }
  set {
    name       = "config.makeArchive"
    value      = try(each.value.archive, local.archive)
  }
  set {
    name       = "config.rescueNotify"
    value      = try(each.value.rescue_email_notify, local.rescue_email_notify)
  }
  set {
    name       = "config.createChecksum"
    value      = try(each.value.create_checksum, local.create_checksum)
  }
  set {
    name       = "config.gpgEncrypt"
    value      = try(each.value.gpg_encrypt, local.gpg_encrypt)
  }
  set {
    name       = "config.FileExt"
    value      = try(each.value.file_ext, local.file_ext)
  }
  set {
    name       = "config.includeHeaders"
    value      = try(each.value.include_headers, local.include_headers)
  }
  set {
    name       = "config.opNotify"
    value      = try(each.value.op_notify, local.op_notify)
  }
  set {
    name       = "jobConfigMapName"
    value      = "sftp-job-config-${each.key}"
  }
  set {
      name     = "jobCredsSecretName"
      value    = "sftp-job-creds-${each.key}"
  }
}

data "vault_generic_secret" "minio_creds" {
  path         = "secret/minio/users"
}

resource "kubernetes_secret" "minio_creds" {
  for_each     = local.minio_users
  metadata {
    name       = "sftp-job-minio-user-${each.key}"
    namespace  = each.value[0]
  }
  data = {
    access_key = jsondecode(data.vault_generic_secret.minio_creds.data[each.key]).accessKey,
    secret_key = jsondecode(data.vault_generic_secret.minio_creds.data[each.key]).secretKey
  }
}

data "vault_kv_secrets_list_v2" "sftp_job_list" {
  mount = "secret"
  name  = "sftp-jobs"
}

resource "kubernetes_manifest" "externalsecret_sftp_jobs_client_secrets" {
  for_each = local.clients
  manifest = {
    "apiVersion" = "external-secrets.io/v1beta1"
    "kind"       = "ExternalSecret"
    "metadata" = {
      "name" = "sftp-job-creds-${each.key}"
      "namespace" : local.namespace
    }
    "spec" = {
      "dataFrom" = [
        {
          "extract" = {
            "key" = "secret/data/sftp-jobs/${each.key}"
          }
        }
      ]
      "refreshInterval" = "1m"
      "secretStoreRef" = {
        "kind" = "SecretStore"
        "name" = "vault-backend"
      }
      "target" = {
        "name" = "sftp-job-creds-${each.key}"
      }
    }
  }
}

resource "kubernetes_manifest" "externalsecret_global_creds" {
  manifest = {
    "apiVersion" = "external-secrets.io/v1beta1"
    "kind"       = "ExternalSecret"
    "metadata" = {
      "name" = "sftp-job-global-creds"
      "namespace" : local.namespace
    }
    "spec" = {
      "dataFrom" = [
        {
          "extract" = {
            "key" = "secret/data/sftp-jobs-global-creds"
          }
        }
      ]
      "refreshInterval" = "1m"
      "secretStoreRef" = {
        "kind" = "SecretStore"
        "name" = "vault-backend"
      }
      "target" = {
        "name" = "sftp-jobs-global-creds"
      }
    }
  }
}

/*
resource "kubernetes_service_account_v1" "sa" {
  metadata {
    name = "sa-sftp-jobs"
  }
  secret {
    name = "${kubernetes_secret_v1.sa_token.metadata.0.name}"
  }
}

resource "kubernetes_secret_v1" "sa_token" {
  metadata {
    name = "sa-secret-sftp-jobs"
    annotations = {
      "kubernetes.io/service-account.name" = "sa-sftp-jobs"
    }
  }
  type = "kubernetes.io/service-account-token"
}
*/