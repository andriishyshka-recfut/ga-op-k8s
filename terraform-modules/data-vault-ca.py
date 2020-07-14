#!/usr/bin/env python3

# Inspired by https://github.com/aabouzaid/terraform-external-data-source-saltstack-pillar/blob/master/pillar_reader.py

import sys
try:
    import json
except ImportError:
    import simplejson as json
import socket
from OpenSSL import SSL
from OpenSSL import crypto
from urllib.parse import urlparse

# Retrive input params
input_json = sys.stdin.read()
try:
    input_dict = json.loads(input_json)
except ValueError as value_error:
    sys.exit(value_error)

# Get certificate
if urlparse(input_dict["vault_addr"]).scheme == 'https' :
    context = SSL.Context(SSL.SSLv23_METHOD)
    s = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
    connection = SSL.Connection(context,s)
    vault_hostname = urlparse(input_dict["vault_addr"]).hostname
    connection.connect((vault_hostname ,443))
    connection.set_tlsext_host_name(str.encode(vault_hostname))
    connection.setblocking(1)
    out_dict = {}
    try:
        connection.do_handshake()
    except OpenSSL.SSL.WantReadError:
        print("Timeout")
        quit()
    for cert in connection.get_peer_cert_chain():
            subject_str = "".join("/{0:s}={1:s}".format(name.decode(), value.decode()) for name, value in cert.get_subject().get_components() )
            if 'Vault managed Root CA' in subject_str:
                out_dict["ca"] = crypto.dump_certificate(crypto.FILETYPE_PEM, cert).decode('ascii')
else:
    out_dict["ca"] = "http not use certificates"

# Output
output_json = json.dumps(out_dict)
sys.stdout.write(output_json)
