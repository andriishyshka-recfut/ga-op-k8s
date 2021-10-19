 set -e
 set +o history

 eval "$(jq -r '@sh "TOKEN=\(.token) SERVER=\(.server)"')"

export NODE_IP=$( kubectl --server $SERVER --insecure-skip-tls-verify=true --token $TOKEN get nodes -o wide -l workloadsType=data -o 'jsonpath={.items[0].metadata.annotations.projectcalico\.org/IPv4Address }' | awk -F/ '{print $1}')


jq -n --arg ip "$NODE_IP" '{"ip":$ip}'
