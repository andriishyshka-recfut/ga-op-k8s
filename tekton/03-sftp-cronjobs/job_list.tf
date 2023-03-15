locals {
  sftpJobList = {
    "crypto-chainalysis" : {
      "cron" : "15 0 * * *",
      "minio_user" : "logstash-red",
      "delivery_method" : "sftp",
      "sftp_user" : "chainalysis",
      "sftp_port" : "22",
      "sftp_destination" : "in/",
      "file_ext" : "json"
    },
    "minion-creditone-account-daily" : {
      "cron" : "15 0 * * *",
      "minio_user" : "logstash-red",
      "delivery_method" : "sftp",
      "sftp_user" : "creditone",
      "sftp_port" : "22",
      "sftp_destination" : "in/account",
      "file_ext" : "csv",
      "archive" : "zip"
    },
    "minion-creditone-added-daily" : {
      "cron" : "15 0 * * *",
      "minio_user" : "logstash-red",
      "delivery_method" : "sftp",
      "sftp_user" : "creditone",
      "sftp_port" : "22",
      "sftp_destination" : "in/",
      "file_ext" : "csv",
      "archive" : "zip"
    },
    "minion-creditone-pans-daily" : {
      "cron" : "15 0 * * *",
      "minio_user" : "logstash-red",
      "delivery_method" : "sftp",
      "sftp_user" : "creditone",
      "sftp_port" : "22",
      "sftp_destination" : "in/pan",
      "file_ext" : "csv",
      "archive" : "zip"
    },
    "minion-dscvr-added-bihourly" : {
      "cron" : "15 */2 * * *",
      "minio_user" : "logstash-red",
      "delivery_method" : "sftp",
      "sftp_user" : "dscvr",
      "sftp_port" : "22",
      "sftp_destination" : "in/",
      "file_ext" : "csv",
      "gpg_encrypt" : true
    },
    "minion-dscvr-pans-daily" : {
      "cron" : "15 0 * * *",
      "minio_user" : "logstash-red",
      "delivery_method" : "sftp",
      "sftp_user" : "dscvr",
      "sftp_port" : "22",
      "sftp_destination" : "in/",
      "file_ext" : "csv",
      "gpg_encrypt" : true
    },
    "minion-test-pans-daily" : {
      "cron" : "0 */1 * * *",
      "minio_user" : "logstash-red",
      "delivery_method" : "sftp",
      "sftp_user" : "alexus",
      "sftp_port" : "22",
      "sftp_destination" : "in/",
      "file_ext" : "csv",
      "gpg_encrypt" : true
    },
    "minion-s3-added-daily" : {
      "cron" : "15 0 * * *",
      "minio_user" : "logstash-red",
      "delivery_method" : "sftp",
      "client_notify" : "email",
      "sftp_user" : "s3",
      "sftp_port" : "22",
      "sftp_destination" : "in/",
      "file_ext" : "csv",
      "archive" : "zip"
    },
    "minion-bmo-pans-daily" : {
      "cron" : "15 0 * * *",
      "minio_user" : "logstash-red",
    }
  }
}
