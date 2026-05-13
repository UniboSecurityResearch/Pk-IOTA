#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

if [[ $# -ne 1 ]]; then
  echo "Usage: $0 forward|extraction" >&2
  exit 1
fi

case "$1" in
  forward)
    cp "$SCRIPT_DIR/s1/forward.p4" "$SCRIPT_DIR/s1/active.p4"
    ;;
  extraction)
    cp "$SCRIPT_DIR/s1/opcua_extraction.p4" "$SCRIPT_DIR/s1/active.p4"
    ;;
  *)
    echo "Invalid variant: $1" >&2
    exit 1
    ;;
esac

echo "Switched active P4 program to: $1"
