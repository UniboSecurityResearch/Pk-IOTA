#!/usr/bin/env bash
set -euo pipefail

if [[ $# -ne 2 ]]; then
  echo "Usage: $0 <server_thumb_hex> <client_thumb_hex>" >&2
  echo "Example: $0 0xabc... 0xdef..." >&2
  exit 1
fi

SERVER_THUMB="$1"
CLIENT_THUMB="$2"

simple_switch_CLI <<EOF
table_clear thumbprint_table
table_add thumbprint_table NoAction ${SERVER_THUMB} =>
table_add thumbprint_table NoAction ${CLIENT_THUMB} =>
table_dump thumbprint_table
EOF
