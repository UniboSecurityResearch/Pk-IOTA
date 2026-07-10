#!/usr/bin/env python3
"""Generic report generator for the OPC UA/P4 overhead testbeds."""

from __future__ import annotations

import argparse
import csv
import math
import sys
from collections import defaultdict
from dataclasses import dataclass
from datetime import datetime, timezone
from pathlib import Path
from statistics import mean
from typing import Dict, Iterable, List, Mapping, Optional, Sequence, Tuple

from common_pcap_analysis import (
    CLASS_OPN_CERT,
    SUMMARY_METRICS,
    analyze_paths,
    ci95_for_deltas,
    class_all,
    classes_for_port,
    fmt,
    ingress_fingerprint,
)


VARIANTS = ("ip_forward", "opcua_forward", "extraction")
VARIANT_ALIASES = {"forward": "opcua_forward"}
DELTA_PAIRS = (
    ("ip_forward", "opcua_forward"),
    ("opcua_forward", "extraction"),
    ("ip_forward", "extraction"),
)


@dataclass(frozen=True)
class CaptureRecord:
    run_index: int
    variant: str
    dims: Tuple[Tuple[str, str], ...]
    ingress_pcaps: Tuple[Path, ...]
    egress_pcaps: Tuple[Path, ...]
    metadata_path: Optional[Path] = None


def canonical_variant(name: str) -> str:
    return VARIANT_ALIASES.get(name, name)


def parse_metadata(path: Optional[Path]) -> Dict[str, str]:
    out: Dict[str, str] = {}
    if path is None or not path.is_file():
        return out
    for raw in path.read_text(encoding="utf-8", errors="ignore").splitlines():
        line = raw.strip()
        if not line or "=" not in line:
            continue
        key, value = line.split("=", 1)
        out[key.strip()] = value.strip()
    return out


def dim_value(dims: Tuple[Tuple[str, str], ...], key: str) -> str:
    return dict(dims).get(key, "")


def markdown_table(headers: List[str], rows: List[List[str]]) -> str:
    sep = ["---"] * len(headers)
    out = ["| " + " | ".join(headers) + " |", "| " + " | ".join(sep) + " |"]
    for row in rows:
        out.append("| " + " | ".join(row) + " |")
    return "\n".join(out)


def write_csv(path: Path, rows: List[Dict[str, str]], fieldnames: List[str]) -> None:
    with path.open("w", newline="", encoding="utf-8") as f:
        writer = csv.DictWriter(f, fieldnames=fieldnames)
        writer.writeheader()
        writer.writerows(rows)


def discover_simple(input_dir: Path, ingress_name: str, egress_name: str) -> List[CaptureRecord]:
    out: List[CaptureRecord] = []
    for run_dir in sorted(input_dir.glob("run_*")):
        if not run_dir.is_dir():
            continue
        try:
            run_idx = int(run_dir.name.replace("run_", ""))
        except ValueError:
            continue
        for variant_dir in sorted(p for p in run_dir.iterdir() if p.is_dir()):
            variant = canonical_variant(variant_dir.name)
            if variant not in VARIANTS:
                continue
            ingress = variant_dir / ingress_name
            egress = variant_dir / egress_name
            if ingress.is_file() and egress.is_file():
                out.append(
                    CaptureRecord(
                        run_idx,
                        variant,
                        tuple(),
                        (ingress,),
                        (egress,),
                        variant_dir / "metadata.env",
                    )
                )
    return out


def discover_switches(input_dir: Path, switches: Sequence[str]) -> List[CaptureRecord]:
    out: List[CaptureRecord] = []
    for run_dir in sorted(input_dir.glob("run_*")):
        if not run_dir.is_dir():
            continue
        try:
            run_idx = int(run_dir.name.replace("run_", ""))
        except ValueError:
            continue
        for variant_dir in sorted(p for p in run_dir.iterdir() if p.is_dir()):
            variant = canonical_variant(variant_dir.name)
            if variant not in VARIANTS:
                continue
            for sw in switches:
                ingress = tuple(sorted(variant_dir.glob(f"{sw}_eth*_in.pcap")))
                egress = tuple(sorted(variant_dir.glob(f"{sw}_eth*_out.pcap")))
                if ingress and egress:
                    out.append(
                        CaptureRecord(
                            run_idx,
                            variant,
                            (("switch", sw),),
                            ingress,
                            egress,
                            variant_dir / "metadata.env",
                        )
                    )
    return out


def discover_cert_size(input_dir: Path) -> List[CaptureRecord]:
    out: List[CaptureRecord] = []
    for run_dir in sorted(input_dir.glob("run_*")):
        if not run_dir.is_dir():
            continue
        try:
            run_idx = int(run_dir.name.replace("run_", ""))
        except ValueError:
            continue
        for kdir in sorted(run_dir.glob("k*")):
            if not kdir.is_dir() or not kdir.name[1:].isdigit():
                continue
            key_bits = kdir.name[1:]
            for variant_dir in sorted(p for p in kdir.iterdir() if p.is_dir()):
                variant = canonical_variant(variant_dir.name)
                if variant not in VARIANTS:
                    continue
                ingress = tuple(sorted(variant_dir.glob("s1_eth*_in.pcap")))
                egress = tuple(sorted(variant_dir.glob("s1_eth*_out.pcap")))
                if ingress and egress:
                    out.append(
                        CaptureRecord(
                            run_idx,
                            variant,
                            (("key_bits", key_bits),),
                            ingress,
                            egress,
                            variant_dir / "metadata.env",
                        )
                    )
    return out


def build_arg_parser(description: str) -> argparse.ArgumentParser:
    parser = argparse.ArgumentParser(description=description)
    parser.add_argument("--input-dir", required=True)
    parser.add_argument("--output-dir", default=None)
    parser.add_argument("--fail-on-quality", action="store_true")
    parser.add_argument("--max-drop-pct", type=float, default=0.0)
    parser.add_argument("--require-extraction-opn-cert", action="store_true")
    parser.add_argument("--require-same-ingress", action="store_true")
    return parser


def _quality_status(
    variants: Mapping[str, Dict[str, Dict[str, float]]],
    fingerprints: Mapping[str, str],
    port: int,
    max_drop_pct: float,
    require_extraction_opn_cert: bool,
    require_same_ingress: bool,
) -> Tuple[str, str]:
    reasons: List[str] = []
    all_cls = class_all(port)
    for variant, values in sorted(variants.items()):
        all_values = values[all_cls]
        if int(all_values["ingress_packets"]) == 0 or int(all_values["egress_packets"]) == 0:
            reasons.append(f"{variant}:empty_capture")
        if int(all_values["matched_packets"]) == 0:
            reasons.append(f"{variant}:no_matches")
        rst_total = int(all_values["rst_ingress"]) + int(all_values["rst_egress"])
        if rst_total > 0:
            reasons.append(f"{variant}:rst={rst_total}")
        neg = int(all_values["negative_delay_matches"])
        if neg > 0:
            reasons.append(f"{variant}:negative_delay={neg}")
        drop = all_values["drop_rate_pct"]
        if not math.isnan(drop) and drop > max_drop_pct:
            reasons.append(f"{variant}:drop={fmt(drop)}")

    if require_extraction_opn_cert and "extraction" in variants:
        cert_packets = int(variants["extraction"][CLASS_OPN_CERT]["ingress_packets"])
        if cert_packets == 0:
            reasons.append("extraction:no_opn_cert")

    if require_same_ingress and len(set(fingerprints.values())) > 1:
        reasons.append("variant_ingress_fingerprint_mismatch")

    return ("pass", "ok") if not reasons else ("fail", ";".join(reasons))


def run_report(
    *,
    title: str,
    input_dir: Path,
    output_dir: Path,
    port: int,
    records: List[CaptureRecord],
    dim_names: Sequence[str],
    fail_on_quality: bool,
    max_drop_pct: float,
    require_extraction_opn_cert: bool,
    require_same_ingress: bool,
    metadata_fields: Sequence[str] = (),
) -> bool:
    if not records:
        raise SystemExit(f"No valid captures found in {input_dir}")

    output_dir.mkdir(parents=True, exist_ok=True)
    classes = classes_for_port(port)

    values: Dict[
        Tuple[int, Tuple[Tuple[str, str], ...]],
        Dict[str, Dict[str, Dict[str, float]]],
    ] = defaultdict(dict)
    fingerprints: Dict[Tuple[int, Tuple[Tuple[str, str], ...]], Dict[str, str]] = defaultdict(dict)

    per_run_rows: List[Dict[str, str]] = []
    for rec in records:
        result = analyze_paths(rec.ingress_pcaps, rec.egress_pcaps, port)
        values[(rec.run_index, rec.dims)][rec.variant] = result
        fingerprints[(rec.run_index, rec.dims)][rec.variant] = ingress_fingerprint(rec.ingress_pcaps, port)
        meta = parse_metadata(rec.metadata_path)
        for traffic_class in classes:
            row: Dict[str, str] = {
                "run_index": str(rec.run_index),
                "variant": rec.variant,
                "traffic_class": traffic_class,
            }
            for name in dim_names:
                row[name] = dim_value(rec.dims, name)
            for field in metadata_fields:
                row[field] = meta.get(field, "nan")
            for metric in SUMMARY_METRICS:
                row[metric] = fmt(result[traffic_class][metric])
            per_run_rows.append(row)

    per_run_fieldnames = ["run_index", *dim_names, "variant", "traffic_class", *metadata_fields, *SUMMARY_METRICS]
    write_csv(output_dir / "per_run.csv", per_run_rows, per_run_fieldnames)

    summary_rows: List[Dict[str, str]] = []
    dim_keys = sorted({dims for _run_idx, dims in values.keys()})
    for dims in dim_keys:
        for traffic_class in classes:
            for metric in SUMMARY_METRICS:
                for baseline, candidate in DELTA_PAIRS:
                    base_vals: List[float] = []
                    cand_vals: List[float] = []
                    deltas: List[float] = []
                    for run_idx in sorted({run for run, d in values.keys() if d == dims}):
                        variants = values.get((run_idx, dims), {})
                        if baseline not in variants or candidate not in variants:
                            continue
                        base = variants[baseline][traffic_class][metric]
                        cand = variants[candidate][traffic_class][metric]
                        if math.isnan(base) or math.isnan(cand):
                            continue
                        base_vals.append(base)
                        cand_vals.append(cand)
                        deltas.append(cand - base)
                    base_mean = mean(base_vals) if base_vals else float("nan")
                    cand_mean = mean(cand_vals) if cand_vals else float("nan")
                    delta_abs = mean(deltas) if deltas else float("nan")
                    delta_pct = (100.0 * delta_abs / base_mean) if base_vals and base_mean != 0 else float("nan")
                    ci_low, ci_high = ci95_for_deltas(deltas)
                    row = {
                        "traffic_class": traffic_class,
                        "metric": metric,
                        "baseline_variant": baseline,
                        "candidate_variant": candidate,
                        "n_pairs": str(len(deltas)),
                        "baseline_mean": fmt(base_mean),
                        "candidate_mean": fmt(cand_mean),
                        "delta_abs": fmt(delta_abs),
                        "delta_pct": fmt(delta_pct),
                        "ci95_low": fmt(ci_low),
                        "ci95_high": fmt(ci_high),
                    }
                    for name in dim_names:
                        row[name] = dim_value(dims, name)
                    summary_rows.append(row)

    summary_fieldnames = [
        *dim_names,
        "traffic_class",
        "metric",
        "baseline_variant",
        "candidate_variant",
        "n_pairs",
        "baseline_mean",
        "candidate_mean",
        "delta_abs",
        "delta_pct",
        "ci95_low",
        "ci95_high",
    ]
    write_csv(output_dir / "summary.csv", summary_rows, summary_fieldnames)

    quality_rows: List[Dict[str, str]] = []
    quality_failed = False
    for (run_idx, dims), variants in sorted(values.items()):
        status, reasons = _quality_status(
            variants,
            fingerprints[(run_idx, dims)],
            port,
            max_drop_pct,
            require_extraction_opn_cert,
            require_same_ingress,
        )
        if status != "pass":
            quality_failed = True
        row = {
            "run_index": str(run_idx),
            "variants_present": ",".join(sorted(variants.keys())),
            "status": status,
            "reasons": reasons,
        }
        for name in dim_names:
            row[name] = dim_value(dims, name)
        for variant in VARIANTS:
            if variant in variants:
                all_values = variants[variant][class_all(port)]
                row[f"{variant}_ingress_packets"] = str(int(all_values["ingress_packets"]))
                row[f"{variant}_matched_packets"] = str(int(all_values["matched_packets"]))
                row[f"{variant}_drop_rate_pct"] = fmt(all_values["drop_rate_pct"])
                row[f"{variant}_rst_total"] = str(int(all_values["rst_ingress"]) + int(all_values["rst_egress"]))
                row[f"{variant}_negative_delay_matches"] = str(int(all_values["negative_delay_matches"]))
                row[f"{variant}_opn_cert_ingress"] = str(int(variants[variant][CLASS_OPN_CERT]["ingress_packets"]))
                row[f"{variant}_ingress_fingerprint"] = fingerprints[(run_idx, dims)][variant]
            else:
                row[f"{variant}_ingress_packets"] = "missing"
                row[f"{variant}_matched_packets"] = "missing"
                row[f"{variant}_drop_rate_pct"] = "missing"
                row[f"{variant}_rst_total"] = "missing"
                row[f"{variant}_negative_delay_matches"] = "missing"
                row[f"{variant}_opn_cert_ingress"] = "missing"
                row[f"{variant}_ingress_fingerprint"] = "missing"
        quality_rows.append(row)

    quality_fieldnames = [
        "run_index",
        *dim_names,
        "variants_present",
        "status",
        "reasons",
    ]
    for variant in VARIANTS:
        quality_fieldnames.extend(
            [
                f"{variant}_ingress_packets",
                f"{variant}_matched_packets",
                f"{variant}_drop_rate_pct",
                f"{variant}_rst_total",
                f"{variant}_negative_delay_matches",
                f"{variant}_opn_cert_ingress",
                f"{variant}_ingress_fingerprint",
            ]
        )
    write_csv(output_dir / "quality.csv", quality_rows, quality_fieldnames)

    now = datetime.now(timezone.utc).isoformat()
    lines = [
        f"# {title}",
        "",
        f"- Generated at: `{now}`",
        f"- Input dir: `{input_dir}`",
        f"- TCP port: `{port}`",
        f"- Capture units discovered: `{len(records)}`",
        "",
        "## Quality",
        "",
    ]
    q_headers = ["run", *dim_names, "variants", "status", "reasons"]
    q_rows = [
        [row["run_index"], *[row.get(name, "") for name in dim_names], row["variants_present"], row["status"], row["reasons"]]
        for row in quality_rows
    ]
    lines.append(markdown_table(q_headers, q_rows))
    lines.extend(["", "## Summary Deltas", ""])

    md_rows: List[List[str]] = []
    for row in summary_rows:
        if row["metric"] not in ("latency_mean_ms", "latency_p95_ms", "drop_rate_pct", "unmatched_ingress"):
            continue
        md_rows.append(
            [
                *[row.get(name, "") for name in dim_names],
                row["traffic_class"],
                row["metric"],
                f"{row['candidate_variant']} - {row['baseline_variant']}",
                row["n_pairs"],
                row["baseline_mean"],
                row["candidate_mean"],
                row["delta_abs"],
                row["delta_pct"],
            ]
        )
    lines.append(
        markdown_table(
            [*dim_names, "class", "metric", "delta", "n_pairs", "baseline", "candidate", "delta_abs", "delta_pct"],
            md_rows,
        )
    )
    lines.extend(
        [
            "",
            "Artifacts:",
            "- `per_run.csv`",
            "- `summary.csv`",
            "- `quality.csv`",
            "- `report.md`",
            "",
        ]
    )
    (output_dir / "report.md").write_text("\n".join(lines), encoding="utf-8")

    print(f"Generated: {output_dir / 'per_run.csv'}")
    print(f"Generated: {output_dir / 'summary.csv'}")
    print(f"Generated: {output_dir / 'quality.csv'}")
    print(f"Generated: {output_dir / 'report.md'}")

    if quality_failed:
        # Say WHY on the console: campaign logs must be self-explanatory, the
        # exit code alone sends people digging through quality.csv.
        for row in quality_rows:
            if row["status"] == "pass":
                continue
            dims_desc = " ".join(f"{name}={row.get(name, '')}" for name in dim_names)
            print(
                f"QUALITY FAIL: run={row['run_index']} {dims_desc} reasons={row['reasons']}".replace("  ", " "),
                file=sys.stderr,
            )
        if fail_on_quality:
            print("Exiting non-zero because --fail-on-quality is set.", file=sys.stderr)
            return False
    return True
