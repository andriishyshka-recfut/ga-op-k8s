 set -e
 set +o history

 eval "$(jq -r '@sh "TOKEN=\(.token) SERVER=\(.server)"')"

export NODE_IP=$( kubectl --server $SERVER \
              --insecure-skip-tls-verify=true \
              --token $TOKEN get nodes -o wide \
               -l workloadsType=data \
               -o 'jsonpath={.items[0].status.addresses[0].address }'

export MONGO_DNS=$( kubectl --server $SERVER \
              --insecure-skip-tls-verify=true \
              --token $TOKEN  get po -n mongo \
              -l app.kubernetes.io/replset=rs0 \
              -o jsonpath='{range .items[*]}{"{\"ip\": \""}{@.status.podIP}","hostname": "{@.metadata.name}.{@.spec.subdomain}.{@.metadata.namespace}{".svc.cluster.local\"},"}{end} ' | \
               sed -e 's/^/[/' -e 's/, $/]/' )


jq -n --arg ip "$NODE_IP" --arg dns "$MONGO_DNS" '{"ip":$ip,"mongo_dns":$dns}'
