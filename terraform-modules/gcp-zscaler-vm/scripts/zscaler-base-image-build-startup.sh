#!/usr/bin/bash
set -euo pipefail

dnf install -y yum-utils
yum-config-manager --add-repo https://rpm.releases.hashicorp.com/RHEL/hashicorp.repo

cat > /etc/yum.repos.d/zscaler.repo <<'EOT'
[zscaler]
name=Zscaler Private Access Repository
baseurl=https://yum.private.zscaler.com/yum/el9
enabled=1
gpgcheck=1
gpgkey=https://yum.private.zscaler.com/yum/el9/gpg
EOT

sleep 15
yum update -y
dnf install -y vault
yum install -y zpa-connector
systemctl enable zpa-connector
systemctl stop zpa-connector || true

mkdir -p /opt/zscaler/var
rm -f /opt/zscaler/var/provision_key || true
echo "ZSCALER_BASE_IMAGE_BUILD_READY"
