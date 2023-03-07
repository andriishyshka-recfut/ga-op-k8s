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
      "cron" : "0 */2 * * *",
      "minio_user" : "logstash-red",
      "delivery_method" : "sftp",
      "sftp_user" : "dscvr",
      "sftp_port" : "22",
      "sftp_destination" : "in/",
      "file_ext" : "csv",
      "gpg_encrypt" : true
    },
    "minion-dscvr-pans-daily" : {
      "cron" : "0 0 * * *",
      "minio_user" : "logstash-red",
      "delivery_method" : "sftp",
      "sftp_user" : "dscvr",
      "sftp_port" : "22",
      "sftp_destination" : "in/",
      "file_ext" : "csv",
      "gpg_encrypt" : true
    }
  }
}
