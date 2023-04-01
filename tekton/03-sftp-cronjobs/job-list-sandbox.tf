locals {
  sftpJobListSandbox = {
    "minion-desjardins-added-daily" : {
      "bucket":"minio-logstash-pipelines-ardent-rarity-239115",
      "minio_user": "backup",
      "cron": "0 0 * * 0",
      "minio_url": "https://minio.t.regemini.io",
      "sftp" : true,
      "sftp_user" : "desjardins",
      "sftp_host": "desjardins-sftp.regemini.com",
      "sftp_port" : "2222",
      "sftp_destination" : "in/",
      "gpg_encrypt" : true,
      "file_ext" : "csv"
    },
    "minion-fiserv-pans-daily" : {
      "bucket":"minio-logstash-pipelines-ardent-rarity-239115",
      "minio_user": "backup",
      "minio_url": "https://minio.t.regemini.io",
      "sftp" : true,
      "sftp_user" : "CAT-NAGW-TVBRR001",
      "sftp_host": "test-gw-na.firstdataclients.com",
      "sftp_options" : "-oHostKeyAlgorithms=+ssh-rsa -oPubkeyAcceptedKeyTypes=+ssh-rsa",
      "sftp_port" : "6522",
      "sftp_destination" : "Inbox/",
      "archive": "gz",
      "gpg_encrypt" : true,
      "file_ext" : "csv"
    }
  }
}