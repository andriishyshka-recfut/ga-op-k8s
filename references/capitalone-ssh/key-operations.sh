#!/usr/bin/env bash

set -euo pipefail

# safe permissions for created files
umask 077

usage() {
  echo "Usage: $0 {generate|rotate}" >&2
  exit 1
}

validate_arguments() {
  if [[ $# -ne 1 ]]; then
    usage
  fi

  action=$1
  if [[ "$action" != generate && "$action" != rotate ]]; then
    usage
  fi
}

load_config() {
  config="$script_dir/secrets-path.json"
  if ! jq -e '.secrets | type == "array" and length > 0 and all(.[]; type == "string" and length > 0)' "$config" >/dev/null; then
    echo "$config must contain a non-empty array of secret paths" >&2
    exit 1
  fi

  # load into bash array
  mapfile -t secrets < <(jq -r '.secrets[]' "$config")
}

validate_commands() {
  for command in vault jq ssh-keygen openssl python3 base64 cmp cut; do
    if ! command -v "$command" >/dev/null; then
      echo "Missing command: $command" >&2
      exit 1
    fi
  done

  if ! python3 -c 'import cryptography' >/dev/null 2>&1; then
    echo "Missing Python package: cryptography" >&2
    exit 1
  fi
}

read_secrets() {
  for i in "${!secrets[@]}"; do
    vault kv get -mount=secret -format=json "${secrets[$i]}" >"$tmp/$i.json"

    if ! jq -er '.data.data.id_rsa1 | strings | select(length > 0) | sub("[\\r\\n]+$"; "")' "$tmp/$i.json" >"$tmp/rsa1.$i"; then
      echo "${secrets[$i]}: missing id_rsa1" >&2
      exit 1
    fi

    if ((i > 0)) && ! cmp -s "$tmp/rsa1.0" "$tmp/rsa1.$i"; then
      echo "id_rsa1 values are not the same in every secret" >&2
      exit 1
    fi

    if [[ "$action" == generate ]] && ! jq -e '.data.data | (has("id_rsa2") and .id_rsa2 == null)' "$tmp/$i.json" >/dev/null; then
      echo "${secrets[$i]}: rotate existing id_rsa2 key before generating a new one" >&2
      exit 1
    fi

    if [[ "$action" == rotate ]]; then
      if ! jq -er '.data.data.id_rsa2 | strings | select(length > 0) | sub("[\\r\\n]+$"; "")' "$tmp/$i.json" >"$tmp/rsa2.$i"; then
        echo "${secrets[$i]}: id_rsa2 must contain a private key" >&2
        exit 1
      fi
    fi

    if [[ "$action" == rotate ]] && ((i > 0)) && ! cmp -s "$tmp/rsa2.0" "$tmp/rsa2.$i"; then
      echo "id_rsa2 values are not the same in every secret" >&2
      exit 1
    fi
  done

  if ! ssh-keygen -y -P '' -f "$tmp/rsa1.0" >"$tmp/rsa1.pub"; then
    echo "id_rsa1 is not a valid unencrypted OpenSSH private key" >&2
    exit 1
  fi

  if [[ $(cut -d' ' -f1 "$tmp/rsa1.pub") != ssh-ed25519 ]]; then
    echo "id_rsa1 must be an unencrypted Ed25519 private key" >&2
    exit 1
  fi
}

generate() {
  # generate keypair
  ssh-keygen -q -t ed25519 -C "cfxp.capitalone.com" -f "$tmp/capitalone" -N ""

  # format old key to PEM
  python3 - "$tmp/rsa1.0" "$tmp/rsa1.pem" <<'PY'
import sys
from cryptography.hazmat.primitives.serialization import Encoding, NoEncryption, PrivateFormat, load_ssh_private_key

key = load_ssh_private_key(open(sys.argv[1], "rb").read(), password=None)
open(sys.argv[2], "wb").write(key.private_bytes(Encoding.PEM, PrivateFormat.PKCS8, NoEncryption()))
PY

  # sign new key with old one
  openssl dgst -sign "$tmp/rsa1.pem" -out "$tmp/sig.bin" "$tmp/capitalone.pub"

  jq -n --rawfile key "$tmp/capitalone" '{id_rsa2: $key}' >"$tmp/patch.json"
  for secret in "${secrets[@]}"; do
    vault kv patch -mount=secret "$secret" @"$tmp/patch.json"
  done

  # print signature and public key, and save to files
  echo "---------"
  echo "sig.bin.b64=$(base64 -w 0 <"$tmp/sig.bin")"
  echo "capitalone.pub.b64=$(base64 -w 0 <"$tmp/capitalone.pub")"
  echo "---------"
  base64 -w 0 <"$tmp/sig.bin" >"$script_dir/sig.bin.b64"
  base64 -w 0 <"$tmp/capitalone.pub" >"$script_dir/capitalone.pub.b64"
}

rotate() {
  jq -n --rawfile key "$tmp/rsa2.0" '{id_rsa1: $key, id_rsa2: null}' >"$tmp/patch.json"
  for secret in "${secrets[@]}"; do
    vault kv patch -mount=secret "$secret" @"$tmp/patch.json"
  done
}

main() {
  VAULT_ADDR="https://vault.p.regemini.io"
  script_dir="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"

  # safe temp dir
  tmp="$script_dir/temp"
  if [[ -d "$tmp" ]]; then
    echo "$tmp must not exist before running the script" >&2
    exit 1
  fi
  mkdir -m 700 -- "$tmp"
  trap 'rm -r -- "$tmp"' EXIT

  validate_arguments "$@"
  validate_commands
  load_config

  read_secrets

  if [[ "$action" == generate ]]; then
    generate
  fi
  if [[ "$action" == rotate ]]; then
    rotate
  fi
}

main "$@"
