variable "BackupSettings" {}
variable "Cluster" {}
variable "Color" {}

data "google_project" "current_project" {
}

locals {
  currentProject = split("/", data.google_project.current_project.id)[1]
  backupCommand  = <<EOT
set -e;
apk add redis;
wget --quiet https://dl.min.io/client/mc/release/linux-amd64/mc ;
chmod +x mc ;
%{for setting in var.BackupSettings}
readarray -d , -t redis_list < redis-cli -h ${setting.service}.${setting.ns} -p ${setting.port} --csv SENTINEL get-master-addr-by-name mymaster;
redis_url = echo \$\{redis_list[0]\} | sed 's/"//g';
redis_port = echo \$\{redis_list[1]\} | sed 's/"//g';
rdt -b redis://$redis_url:$redis_port -o ${setting.name}.rdb;
/mc cp ${setting.name}.rdb backup/minio-xbackup-${local.currentProject}/redis-backup/${setting.name}.rdb;
%{endfor}
EOT
}
