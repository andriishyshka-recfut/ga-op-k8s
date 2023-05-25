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
    #"minion-test-pans-daily" : {
    #  "minio_user" : "logstash-red",
    #  "sftp" : true,
    #  "sftp_user" : "alexus",
    #  "sftp_port" : "22",
    #  "sftp_destination" : "in/",
    #  "file_ext" : "csv",
    #  "email" : true,
    #  "email_subject": "[FEED] - TEST'PANS"
    #},
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
    #"minion-fiserv-added-daily" : {
    #  "minio_user" : "logstash-red",
    #  "sftp" : true,
    #  "sftp_user" : "fiserv",
    #  "sftp_port" : "22"
    #  "sftp_destination" : "in/",
    #  "file_ext" : "csv",
    #  "archive" : "gz"
    #},
    #"minion-fiserv-pans-daily" : {
    #  "minio_user": "logstash-red",
    #  "sftp" : true,
    #  "sftp_user" : "PROD-NAGW-TVBRR001",
    #  "sftp_host": "prod-gw-na.firstdataclients.com",
    #  "sftp_port" : "6522",
    #  "sftp_options" : "-oHostKeyAlgorithms=+ssh-rsa -oPubkeyAcceptedKeyTypes=+ssh-rsa",
    #  "sftp_destination" : "",
    #  "gpg_encrypt" : true,
    #  "file_ext" : "csv"
    #},
    "minion-bmo-pans-daily" : {
      "minio_user" : "logstash-red",
      "email" : true,
      "email_subject": "[FEED] - BMO'PANS"
      "archive" : "zip",
      "file_ext" : "CSV"
    },
    "minion-bmo-added-daily" : {
      "minio_user" : "logstash-red",
      "sftp" : true,
      "sftp_user" : "bmo",
      "sftp_port" : "22"
      "sftp_destination" : "in/",
      "gpg_encrypt" : true,
      "file_ext" : "csv"
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
    "minion-synchrony-pans-weekly" : {
      "minio_user" : "logstash-red",
      "cron" : "0 0 * * 5",
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
    },
    "minion-eml-added-daily" : {
      "minio_user" : "logstash-red",
      "sftp" : true,
      "sftp_user" : "eml",
      "sftp_port" : "22",
      "sftp_destination" : "in/",
      "file_ext" : "JSON",
      "archive" : "ZIP",
      "create_checksum": true
    },
    "minion-eml-eu-added-daily" : {
      "minio_user" : "logstash-red",
      "email" : true,
      "email_subject": "[FEED] - EML'ADDED"
      "archive" : "zip",
      "file_ext" : "CSV"
    },
    #"minion-banner-added-daily" : {
    #  "minio_user" : "logstash-red",
    #  "email" : true,
    #  "email_subject": "[FEED] - BANNER'ADDED"
    #  "sftp" : false,
    #  "gpg_encrypt" : false,
    #  "sftp_host" : "64.255.194.80",
    #  "sftp_options" : "-oHostKeyAlgorithms=+ssh-rsa -oPubkeyAcceptedKeyTypes=+ssh-rsa",
    #  "sftp_user" : "RecordedFuture",
    #  "sftp_port" : "22",
    #  "sftp_destination" : "",
    #  "archive" : "zip",
    #  "file_ext" : "CSV"
    #},
    #"minion-banner-pans-daily" : {
    #  "minio_user" : "logstash-red",
    #  "email" : true,
    #  "email_subject": "[FEED] - BANNER'PANS"
    #  "archive" : "zip",
    #  "file_ext" : "CSV"
    #}, 
    "minion-desjardins-pans-daily" : {
      "minio_user" : "logstash-red",
      "email" : true,
      "email_subject": "[FEED] - COLLABRIA'PANS"
      "archive" : "ZIP",
      "file_ext" : "CSV"
    },     
  }
}
