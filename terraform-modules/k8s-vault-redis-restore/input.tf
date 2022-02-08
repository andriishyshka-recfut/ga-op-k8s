variable "BackupSettings" {}
variable "Cluster" {}
variable "Color" {}

locals {
  currentProject = var.Cluster == "production" ? "orbital-wording-233917" : "ardent-rarity-239115"
  backupCommand  = <<EOT
set -e;
apk update;
apk add redis;
wget --quiet https://dl.min.io/client/mc/release/linux-amd64/mc;
chmod +x mc;
if [ $SENTINEL = "yes" ]; then
/usr/bin/redis-cli -h $BACKUP_SERVICE_NAME -p $BACKUP_SERVICE_PORT --csv SENTINEL get-master-addr-by-name mymaster > redisdb;
redis_url=`cut -d, -f1<redisdb|sed 's/\"//g'`;
redis_port=`cut -d, -f2<redisdb|sed 's/\"//g'`;
else
redis_url=$BACKUP_SERVICE_NAME;
redis_port=$BACKUP_SERVICE_PORT;
echo "Connect without sentiel";
fi
./mc cp backup/minio-xbackup-${local.currentProject}/redis-backup/$BACKUP_NAME.rdb ./ ;
rmt -s $BACKUP_NAME.rdb -m redis://$redis_url:$redis_port -r;
EOT
}
