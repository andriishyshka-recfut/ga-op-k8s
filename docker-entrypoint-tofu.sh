#!/bin/sh
set -e
eval $(ssh-agent)
cd $CWD
source /ansible/bin/activate
export PYTHONPATH=/ansible/lib/python3.9/site-packages
export HOME=/home/fake
#env
# echo
# echo "You are running from docker"
# echo
#
# ansible --version
# cat /etc/resolv.conf
# export TF_LOG=debug
export TF_CLI_CONFIG_FILE=/etc/tofurc
exec /usr/bin/tofu $@
