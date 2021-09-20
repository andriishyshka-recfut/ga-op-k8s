variable "BackupSettings" {}
variable "Cluster" {}
variable "Color" {}


data "vault_generic_secret" "minio-cred-redis" {
  path = "secret/minio-credentials"
}
locals {
  currentProject = var.Cluster == "production" ? "orbital-wording-233917" : "ardent-rarity-239115"
  backupCommand  = <<EOT
set -e;
apk update;
apk add redis;
wget --quiet https://dl.min.io/client/mc/release/linux-amd64/mc;
chmod +x mc;
/usr/bin/redis-cli -h $BACKUP_SERVICE_NAME -p $BACKUP_SERVICE_PORT --csv SENTINEL get-master-addr-by-name mymaster > redisdb;
redis_url=`cut -d, -f1<redisdb|sed 's/\"//g'`;
redis_port=`cut -d, -f2<redisdb|sed 's/\"//g'`;
date_time=`date '+%Y%m%d-%H:%M:%S'`;
rdt -b redis://$redis_url:$redis_port -o $BACKUP_NAME.rdb;
cp $BACKUP_NAME.rdb BACKUP_NAME-$date_time.rdb;
./mc cp *.rdb backup/minio-xbackup-${local.currentProject}/redis-backup/;
EOT
}
