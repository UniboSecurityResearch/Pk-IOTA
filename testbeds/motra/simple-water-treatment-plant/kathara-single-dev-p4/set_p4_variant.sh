#!/usr/bin/env bash
set -euo pipefail

if [[ $# -ne 1 ]]; then
  echo "Usage: $0 ip_forward|opcua_forward|forward|extraction" >&2
  exit 1
fi

variant="$1"
case "$variant" in
  ip_forward)
    src="ip_forward.p4"
    canonical="ip_forward"
    ;;
  forward|opcua_forward)
    src="forward.p4"
    canonical="opcua_forward"
    ;;
  extraction)
    src="opcua_extraction.p4"
    canonical="extraction"
    ;;
  *)
    echo "Invalid variant: $variant (expected ip_forward|opcua_forward|forward|extraction)" >&2
    exit 1
    ;;
esac

LAB_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
for sw in s_it s_plc s_ot s_lsensor; do
  cp "$LAB_DIR/$sw/$src" "$LAB_DIR/$sw/active.p4"
done

echo "Selected P4 variant: $canonical (copied to active.p4 on all switches)"
