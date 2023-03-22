locals {
  jobs = var.Cluster == "production" ? local.sftpJobList : local.sftpJobListSandbox
  sftpJobList = {
    "crypto-chainalysis" : {
      "minio_user" : "logstash-red",
      "sftp" : true,
      "sftp_user" : "chainalysis",
      "sftp_port" : "22",
      "sftp_destination" : "in/",
      "file_ext" : "json"
    },
    "minion-creditone-account-daily" : {
      "minio_user" : "logstash-red",
      "sftp" : true,
      "sftp_user" : "creditone",
      "sftp_port" : "22",
      "sftp_destination" : "in/account",
      "file_ext" : "csv",
      "archive" : "zip",
      "include_headers": true
    },
    "minion-creditone-added-daily" : {
      "minio_user" : "logstash-red",
      "sftp" : true,
      "sftp_user" : "creditone",
      "sftp_port" : "22",
      "sftp_destination" : "in/",
      "file_ext" : "csv",
      "archive" : "zip",
      "include_headers": true
    },
    "minion-creditone-pans-daily" : {
      "minio_user" : "logstash-red",
      "sftp" : true,
      "sftp_user" : "creditone",
      "sftp_port" : "22",
      "sftp_destination" : "in/pan",
      "file_ext" : "csv",
      "archive" : "zip"
    },
    "minion-dscvr-added-bihourly" : {
      "cron" : "15 */2 * * *",
      "minio_user" : "logstash-red",
      "sftp" : true,
      "sftp_user" : "dscvr",
      "sftp_port" : "22",
      "sftp_destination" : "in/",
      "file_ext" : "csv",
      "gpg_encrypt" : true
    },
    "minion-dscvr-pans-daily" : {
      "minio_user" : "logstash-red",
      "sftp" : true,
      "sftp_user" : "dscvr",
      "sftp_port" : "22",
      "sftp_destination" : "in/",
      "file_ext" : "csv",
      "gpg_encrypt" : true
    },
    "minion-test-pans-daily" : {
      "minio_user" : "logstash-red",
      "sftp" : true,
      "sftp_user" : "alexus",
      "sftp_port" : "22",
      "sftp_destination" : "in/",
      "file_ext" : "csv",
      "email" : true,
      "email_subject": "[FEED] - TEST'PANS"

    },
    "minion-s3-added-daily" : {
      "minio_user" : "logstash-red",
      "sftp" : true,
      "email" : true,
      "email_subject": "[FEED] - S3'ADDED",
      "sftp_user" : "s3",
      "sftp_port" : "22",
      "sftp_destination" : "in/",
      "file_ext" : "csv",
      "archive" : "zip"
    },
    "dome-bka-added-daily" : {
      "minio_user" : "logstash-red",
      "sftp" : true,
      "sftp_user" : "bka",
      "sftp_port" : "22",
      "sftp_destination" : "in/",
      "file_ext" : "json",
      "archive" : "gz",
      "create_checksum": true
    },
    "minion-fiserv-added-daily" : {
      "minio_user" : "logstash-red",
      "sftp" : true,
      "email": true,
      "email_subject": "[FEED] - FISERV'ADDED",
      "sftp_user" : "fiserv",
      "sftp_port" : "22",
      "sftp_destination" : "in/",
      "file_ext" : "csv",
      "archive" : "gz"
    },
    "minion-bmo-pans-daily" : {
      "minio_user" : "logstash-red",
      "email" : true,
      "email_subject": "[FEED] - BMO'PANS"
      "archive" : "zip",
      "file_ext" : "CSV"
    },
    "minion-golomt-pans-daily" : {
      "minio_user" : "logstash-red",
      "email" : true,
      "email_subject": "[FEED] - GOLOMT'PANS"
      "archive" : "zip",
      "file_ext" : "CSV"
    },
    "minion-bnp-added-daily" : {
      "minio_user" : "logstash-red",
      "email" : true,
      "email_subject": "[FEED] - BNP'ADDED"
      "archive" : "zip",
      "file_ext" : "CSV"
    },
    "minion-bnp-pans-daily" : {
      "minio_user" : "logstash-red",
      "email" : true,
      "email_subject": "[FEED] - BNP'PANS"
      "archive" : "zip",
      "file_ext" : "CSV"
    },
    "minion-tjx-added-daily" : {
      "minio_user" : "logstash-red",
      "email" : true,
      "email_subject": "[FEED] - TJX'ADDED"
      "archive" : "zip",
      "file_ext" : "CSV"
    },
    "minion-tjx-pans-daily" : {
      "minio_user" : "logstash-red",
      "email" : true,
      "email_subject": "[FEED] - TJX'PANS"
      "archive" : "zip",
      "file_ext" : "CSV"
    },
    "minion-sainsburys-added-daily" : {
      "minio_user" : "logstash-red",
      "email" : true,
      "email_subject": "[FEED] - SAINSBURYS'ADDED"
      "archive" : "zip",
      "file_ext" : "CSV"
    },
    "minion-sainsburys-pans-daily" : {
      "minio_user" : "logstash-red",
      "email" : true,
      "email_subject": "[FEED] - SAINSBURYS'PANS"
      "archive" : "zip",
      "file_ext" : "CSV"
    },
    "minion-synchrony-pans-daily" : {
      "minio_user" : "logstash-red",
      "email" : true,
      "email_subject": "[FEED] - SYNCHRONY'PANS"
      "archive" : "zip",
      "file_ext" : "csv"
    },
    "minion-greendot-added-daily" : {
      "minio_user" : "logstash-red",
      "email" : true,
      "email_subject": "[FEED] - GREENDOT'ADDED"
      "archive" : "zip",
      "file_ext" : "csv"
    }   
  }
}
