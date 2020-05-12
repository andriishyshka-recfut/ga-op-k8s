#!/bin/sh


rm ./ssh-key-ansible-sa*

ssh-keygen -q  -f ./ssh-key-ansible-sa -N ''

jq -n --arg expiration_date "$(date +"%s%6N" -d '1 hour')" \
  --arg pub_certificate "$(cat ssh-key-ansible-sa.pub)" \
  '{'expiration_date': $expiration_date , 'pub_certificate': $pub_certificate }'
