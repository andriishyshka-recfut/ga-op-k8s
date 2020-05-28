#!/bin/sh

eval $(ssh-agent)
cd $CWD
#env
echo
echo "You are running from docker"
echo

cat /etc/resolv.conf
exec /usr/bin/terraform $@
#cd /home/runner/ansible
#exec ansible-inventory -vvvvvv --list --yaml
