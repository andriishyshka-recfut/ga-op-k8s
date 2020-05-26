#!/bin/sh


rm ./ssh-key-ansible-sa*

ssh-add -D
openssl genrsa 2048 2> /dev/null | ssh-add -

#ssh-keygen -q  -f ./ssh-key-ansible-sa -N ''

jq -n --arg expiration_date "$(date +"%s%6N" -d '1 hour')" \
  --arg pub_certificate "$(ssh-add -L | tail -1)" \
  '{'expiration_date': $expiration_date , 'pub_certificate': $pub_certificate }'
