kubectl get secret/bnp-api-cert -n istio-ingress --template='{{index .data "tls.key" }}'|base64 -d > ./key.pem
kubectl get secret/bnp-api-cert -n istio-ingress --template='{{index .data "tls.crt" }}'|base64 -d > ./cert.pem
curl -o ./ca.pem https://letsencrypt.org/certs/isrgrootx1.pem
openssl pkcs12 -export -in ./cert.pem -inkey ./key.pem -CAfile ./ca.pem -caname "Let's Encrypt Authority X3" -out bnp-api.regemini.com.p12 -name bnp-api.regemini.com
keytool -importkeystore -deststoretype pkcs12 -deststorepass bnp-api -destkeypass bnp-api -srckeystore ./bnp-api.regemini.com.p12 -srcstoretype PKCS12 -destkeystore ./bnp-api.regemini.com.keystore -alias bnp-api.regemini.com
