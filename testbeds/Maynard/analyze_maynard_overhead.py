#!/usr/bin/env python3
"""Analyze Maynard overhead captures."""

from __future__ import annotations

import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
sys.path.insert(0, str(ROOT))

from generic_overhead_analyzer import CaptureRecord, build_arg_parser, discover_simple, discover_switches, run_report


PORT = 8666


def main() -> int:
    parser = build_arg_parser("Analyze Maynard OPC UA/P4 overhead captures.")
    args = parser.parse_args()

    input_dir = Path(args.input_dir)
    output_dir = Path(args.output_dir) if args.output_dir else input_dir
    switch_records = discover_switches(input_dir, ("s1",))
    if switch_records:
        records = [
            CaptureRecord(
                rec.run_index,
                rec.variant,
                tuple(),
                rec.ingress_pcaps,
                rec.egress_pcaps,
                rec.metadata_path,
            )
            for rec in switch_records
        ]
    else:
        records = discover_simple(input_dir, "s1_ingress.pcap", "s1_egress.pcap")
    ok = run_report(
        title="Maynard Overhead Report",
        input_dir=input_dir,
        output_dir=output_dir,
        port=PORT,
        records=records,
        dim_names=(),
        fail_on_quality=args.fail_on_quality,
        max_drop_pct=args.max_drop_pct,
        require_extraction_opn_cert=args.require_extraction_opn_cert,
        require_same_ingress=args.require_same_ingress,
    )
    return 0 if ok else 1


if __name__ == "__main__":
    raise SystemExit(main())
