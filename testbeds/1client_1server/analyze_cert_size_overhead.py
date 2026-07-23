#!/usr/bin/env python3
"""Analyze certificate-size overhead captures for the 1client_1server testbed."""

from __future__ import annotations

import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
sys.path.insert(0, str(ROOT))

from generic_overhead_analyzer import build_arg_parser, discover_cert_size, run_report


PORT = 4840
METADATA_FIELDS = ("server_cert_bytes", "client_cert_bytes", "sessions_ok", "sessions_fail")


def main() -> int:
    parser = build_arg_parser("Analyze certificate-size OPC UA/P4 overhead captures.")
    args = parser.parse_args()

    input_dir = Path(args.input_dir)
    output_dir = Path(args.output_dir) if args.output_dir else input_dir
    records = discover_cert_size(input_dir)
    ok = run_report(
        title="1client_1server Certificate Overhead Report",
        input_dir=input_dir,
        output_dir=output_dir,
        port=PORT,
        records=records,
        dim_names=("key_bits",),
        fail_on_quality=args.fail_on_quality,
        max_drop_pct=args.max_drop_pct,
        max_rst_pct=args.max_rst_pct,
        require_extraction_opn_cert=args.require_extraction_opn_cert,
        require_same_ingress=args.require_same_ingress,
        metadata_fields=METADATA_FIELDS,
    )
    return 0 if ok else 1


if __name__ == "__main__":
    raise SystemExit(main())
