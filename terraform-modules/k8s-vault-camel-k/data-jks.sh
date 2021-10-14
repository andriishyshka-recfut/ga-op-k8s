#!/bin/bash

set -e
set +o history
# Extract input params
eval "$(jq -r '@sh "CLIENT_KEY=\(.clientKey) CLIENT_CRT=\(.clientCrt) CA_CRT=\(.caCrt) KEYSTORE_PASS=\(.keystorePass)"')"


# Generate keystore
echo "${CLIENT_KEY}${CLIENT_CRT}" | openssl pkcs12 -export -name client -out /tmp/client.p12 -password pass:${KEYSTORE_PASS} -in -

/opt/openjdk-18/bin/keytool -importkeystore \
                            -srckeystore /tmp/client.p12 \
                            -srcstoretype pkcs12 \
                            -alias client \
                            -srcstorepass ${KEYSTORE_PASS} \
                            -deststorepass ${KEYSTORE_PASS} \
                            -destkeystore /tmp/keystore \
                            -noprompt 2> /dev/null

echo  "$CA_CRT" > /tmp/ca.crt
#sleep 3600
/opt/openjdk-18/bin/keytool -import -keystore /tmp/keystore -file /tmp/ca.crt -alias server -storepass ${KEYSTORE_PASS} -noprompt -v 2> /dev/null

export KEYSTORE=$(cat /tmp/keystore | base64 )

# return base64 encoded keystore
jq -n --arg keystore "$KEYSTORE" '{"keystore":$keystore}'
