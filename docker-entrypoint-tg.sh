#!/bin/bash
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
#ansible --version
# cat /etc/resolv.conf

export VAULT_ADDR=https://vault.t.regemini.io
export KUBE_CLIENT_CERT_DATA=$(vault kv get -field=k8s_sa_ca_cert secret/kubernetes-sandbox-green )
export KUBE_TOKEN=$(vault kv get -field=k8s_sa_token secret/kubernetes-sandbox-green )
export KUBE_HOST=$(vault kv get -field=HOST secret/kubernetes-sandbox-green )
export KUBE_CLUSTER_CA_CERT_DATA=$(vault kv get -field=CLUSTER_CA_CERTIFICATE secret/kubernetes-sandbox-green )
exec /bin/terragrunt $@
