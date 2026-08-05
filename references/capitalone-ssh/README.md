# Capital One SSH key rotation

The script stages and rotates the same Ed25519 private key across multiple Vault
KV secrets.

```bash
./key-operations.sh generate (produces sig.bin.b64 and capitalone.pub.b64 files)
./key-operations.sh rotate (only after green flag from the client)
```

Secret paths are read from `secrets-path.json`.

`generate` requires the same `id_rsa1` in every secret and a null `id_rsa2`.
It creates a new Ed25519 key, signs its public key with `id_rsa1`,
stores the new private key as `id_rsa2`, and prints the base64-encoded public key
and raw Ed25519 signature. It also saves them beside the script as
`capitalone.pub.b64` and `sig.bin.b64`.

`rotate` requires the same `id_rsa1` and `id_rsa2` in every secret. It promotes
`id_rsa2` to `id_rsa1` and sets `id_rsa2` to null (not "null", but null).

Dependencies:
- vault cli
- openssl 3.6+
- jq
- base64
- python3 with cryptography package installed
  - `brew install cryptography`

Prerequisites:
- Login to Production Vault
