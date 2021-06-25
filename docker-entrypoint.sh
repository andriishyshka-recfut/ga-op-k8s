#!/bin/sh
set -e
eval $(ssh-agent)
cd $CWD
source /ansible/bin/activate
#env
echo
echo "You are running from docker"
echo

id

export PYTHONPATH=/ansible/lib/python3.7/site-packages/
export HOME=/home/fake
env
ansible --version


cat /etc/resolv.conf
exec /bin/terraform $@
#cd /home/runner/ansible
#exec ansible-inventory -vvvvvv --list --yaml
