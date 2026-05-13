#!/usr/bin/env bash
set -euo pipefail

if [[ $# -ne 1 ]]; then
  echo "Usage: $0 forward|extraction" >&2
  exit 1
fi

variant="$1"
case "$variant" in
  forward) src="forward.p4" ;;
  extraction) src="opcua_extraction.p4" ;;
  *)
    echo "Invalid variant: $variant (expected forward|extraction)" >&2
    exit 1
    ;;
esac

LAB_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
for sw in s_it s_plc s_ot s_lsensor; do
  cp "$LAB_DIR/$sw/$src" "$LAB_DIR/$sw/active.p4"
done

echo "Selected P4 variant: $variant (copied to active.p4 on all switches)"
