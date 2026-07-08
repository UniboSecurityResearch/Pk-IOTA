#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

if [[ $# -ne 1 ]]; then
  echo "Usage: $0 ip_forward|opcua_forward|forward|extraction" >&2
  exit 1
fi

variant="$1"
case "$variant" in
  ip_forward)
    src="$SCRIPT_DIR/s1/ip_forward.p4"
    canonical="ip_forward"
    ;;
  forward|opcua_forward)
    src="$SCRIPT_DIR/s1/forward.p4"
    canonical="opcua_forward"
    ;;
  extraction)
    src="$SCRIPT_DIR/s1/opcua_extraction.p4"
    canonical="extraction"
    ;;
  *)
    echo "Invalid variant: $variant" >&2
    exit 1
    ;;
esac

cp "$src" "$SCRIPT_DIR/s1/active.p4"
echo "Switched active P4 program to: $canonical"
