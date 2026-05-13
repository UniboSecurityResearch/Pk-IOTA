#!/usr/bin/env python3
"""Analyze paired Maynard overhead runs from ingress/egress pcap files.

The analyzer computes switch-level packet latency for TCP/8666 and reports:
- opcua_opn: payload starts with b"OPN"
- opcua_other: payload > 0 and not OPN
- opcua_all_8666: all TCP/8666 packets (including zero payload)
"""

from __future__ import annotations

import argparse
import csv
import math
import struct
from collections import defaultdict, deque
from dataclasses import dataclass
from datetime import datetime, timezone
from pathlib import Path
from statistics import mean, median, stdev
from typing import Deque, Dict, Iterable, List, Optional, Tuple

PORT = 8666
CLASS_OPN = "opcua_opn"
CLASS_OTHER = "opcua_other"
CLASS_ALL = "opcua_all_8666"
CLASSES = (CLASS_OPN, CLASS_OTHER, CLASS_ALL)

LATENCY_METRICS = (
    "latency_mean_ms",
    "latency_median_ms",
    "latency_p95_ms",
    "latency_p99_ms",
    "latency_std_ms",
)
COUNT_METRICS = (
    "ingress_packets",
    "egress_packets",
    "matched_packets",
    "unmatched_ingress",
    "unmatched_egress",
    "drop_rate_pct",
    "rst_ingress",
    "rst_egress",
)
SUMMARY_METRICS = LATENCY_METRICS + COUNT_METRICS


@dataclass
class Packet:
    ts: float
    src_ip: str
    dst_ip: str
    src_port: int
    dst_port: int
    seq: int
    ack: int
    flags: int
    payload: bytes

    @property
    def payload_len(self) -> int:
        return len(self.payload)

    @property
    def is_rst(self) -> bool:
        return bool(self.flags & 0x04)

    @property
    def key(self) -> Tuple[str, str, int, int, int, int, int, int]:
        return (
            self.src_ip,
            self.dst_ip,
            self.src_port,
            self.dst_port,
            self.seq,
            self.ack,
            self.flags,
            self.payload_len,
        )


def quantile_sorted(values: List[float], q: float) -> float:
    if not values:
        return float("nan")
    idx = int(math.ceil(q * len(values))) - 1
    idx = max(0, min(idx, len(values) - 1))
    return values[idx]


def ms(value_s: float) -> float:
    return value_s * 1000.0


def t_critical_95(df: int) -> float:
    # Two-tailed 95% confidence; small lookup table then normal approximation.
    table = {
        1: 12.706,
        2: 4.303,
        3: 3.182,
        4: 2.776,
        5: 2.571,
        6: 2.447,
        7: 2.365,
        8: 2.306,
        9: 2.262,
        10: 2.228,
        11: 2.201,
        12: 2.179,
        13: 2.160,
        14: 2.145,
        15: 2.131,
        16: 2.120,
        17: 2.110,
        18: 2.101,
        19: 2.093,
        20: 2.086,
        21: 2.080,
        22: 2.074,
        23: 2.069,
        24: 2.064,
        25: 2.060,
        26: 2.056,
        27: 2.052,
        28: 2.048,
        29: 2.045,
        30: 2.042,
    }
    if df <= 0:
        return float("nan")
    return table.get(df, 1.960)


def fmt(value: float) -> str:
    if value is None or isinstance(value, float) and (math.isnan(value) or math.isinf(value)):
        return "nan"
    return f"{value:.6f}"


def iter_pcap(path: Path) -> Iterable[Tuple[float, bytes]]:
    with path.open("rb") as f:
        header = f.read(24)
        # Empty or truncated capture: treat as no packets instead of aborting
        # the entire analysis run.
        if len(header) == 0:
            return
        if len(header) < 24:
            return

        magic = header[:4]
        if magic == b"\xd4\xc3\xb2\xa1":
            endian = "<"
            ts_scale = 1e-6
        elif magic == b"\xa1\xb2\xc3\xd4":
            endian = ">"
            ts_scale = 1e-6
        elif magic == b"\x4d\x3c\xb2\xa1":
            endian = "<"
            ts_scale = 1e-9
        elif magic == b"\xa1\xb2\x3c\x4d":
            endian = ">"
            ts_scale = 1e-9
        else:
            # Unsupported format (or corrupted header): skip gracefully.
            return

        ph_struct = struct.Struct(f"{endian}IIII")
        while True:
            ph = f.read(16)
            if not ph:
                break
            if len(ph) < 16:
                # Common when capture is interrupted while writing.
                break

            ts_sec, ts_frac, incl_len, _orig_len = ph_struct.unpack(ph)
            data = f.read(incl_len)
            if len(data) < incl_len:
                # Common when capture is interrupted while writing.
                break

            ts = ts_sec + (ts_frac * ts_scale)
            yield ts, data


def parse_ipv4_tcp(ts: float, frame: bytes) -> Optional[Packet]:
    if len(frame) < 14:
        return None

    offset = 14
    ethertype = struct.unpack("!H", frame[12:14])[0]
    if ethertype == 0x8100 and len(frame) >= 18:
        ethertype = struct.unpack("!H", frame[16:18])[0]
        offset = 18

    if ethertype != 0x0800:
        return None
    if len(frame) < offset + 20:
        return None

    ver_ihl = frame[offset]
    version = ver_ihl >> 4
    ihl = (ver_ihl & 0x0F) * 4
    if version != 4 or ihl < 20:
        return None
    if len(frame) < offset + ihl:
        return None

    total_len = struct.unpack("!H", frame[offset + 2 : offset + 4])[0]
    proto = frame[offset + 9]
    if proto != 6:
        return None

    src_ip = ".".join(str(x) for x in frame[offset + 12 : offset + 16])
    dst_ip = ".".join(str(x) for x in frame[offset + 16 : offset + 20])

    tcp_off = offset + ihl
    if len(frame) < tcp_off + 20:
        return None

    src_port, dst_port, seq, ack = struct.unpack("!HHII", frame[tcp_off : tcp_off + 12])
    data_off = (frame[tcp_off + 12] >> 4) * 4
    if data_off < 20:
        return None
    flags = frame[tcp_off + 13]

    ip_end = offset + total_len
    cap_end = min(len(frame), ip_end)
    payload_start = tcp_off + data_off
    if payload_start > cap_end:
        payload = b""
    else:
        payload = frame[payload_start:cap_end]

    return Packet(
        ts=ts,
        src_ip=src_ip,
        dst_ip=dst_ip,
        src_port=src_port,
        dst_port=dst_port,
        seq=seq,
        ack=ack,
        flags=flags,
        payload=payload,
    )


def packet_classes(pkt: Packet) -> List[str]:
    out = [CLASS_ALL]
    if pkt.payload_len > 0:
        if pkt.payload.startswith(b"OPN"):
            out.append(CLASS_OPN)
        else:
            out.append(CLASS_OTHER)
    return out


def safe_mean(values: List[float]) -> float:
    return mean(values) if values else float("nan")


def safe_stdev(values: List[float]) -> float:
    if len(values) <= 1:
        return float("nan")
    return stdev(values)


def analyze_pair(ingress_pcap: Path, egress_pcap: Path) -> Dict[str, Dict[str, float]]:
    ingress_q: Dict[Tuple[str, str, int, int, int, int, int, int], Deque[Tuple[float, List[str]]]] = defaultdict(deque)
    delays_by_class: Dict[str, List[float]] = {c: [] for c in CLASSES}

    ingress_counts = {c: 0 for c in CLASSES}
    egress_counts = {c: 0 for c in CLASSES}
    matched_counts = {c: 0 for c in CLASSES}
    unmatched_ingress = {c: 0 for c in CLASSES}
    unmatched_egress = {c: 0 for c in CLASSES}
    rst_ingress = {c: 0 for c in CLASSES}
    rst_egress = {c: 0 for c in CLASSES}

    for ts, frame in iter_pcap(ingress_pcap):
        pkt = parse_ipv4_tcp(ts, frame)
        if pkt is None:
            continue
        if pkt.src_port != PORT and pkt.dst_port != PORT:
            continue
        cls = packet_classes(pkt)
        for c in cls:
            ingress_counts[c] += 1
            if pkt.is_rst:
                rst_ingress[c] += 1
        ingress_q[pkt.key].append((pkt.ts, cls))

    for ts, frame in iter_pcap(egress_pcap):
        pkt = parse_ipv4_tcp(ts, frame)
        if pkt is None:
            continue
        if pkt.src_port != PORT and pkt.dst_port != PORT:
            continue
        cls = packet_classes(pkt)
        for c in cls:
            egress_counts[c] += 1
            if pkt.is_rst:
                rst_egress[c] += 1

        queue = ingress_q.get(pkt.key)
        if queue and len(queue) > 0:
            ts_in, cls_in = queue.popleft()
            delay = pkt.ts - ts_in
            for c in cls_in:
                delays_by_class[c].append(delay)
                matched_counts[c] += 1
        else:
            for c in cls:
                unmatched_egress[c] += 1

    for queue in ingress_q.values():
        while queue:
            _ts_in, cls_in = queue.popleft()
            for c in cls_in:
                unmatched_ingress[c] += 1

    results: Dict[str, Dict[str, float]] = {}
    for c in CLASSES:
        d = sorted(delays_by_class[c])
        lat_mean_ms = ms(safe_mean(d)) if d else float("nan")
        lat_median_ms = ms(median(d)) if d else float("nan")
        lat_p95_ms = ms(quantile_sorted(d, 0.95)) if d else float("nan")
        lat_p99_ms = ms(quantile_sorted(d, 0.99)) if d else float("nan")
        lat_std_ms = ms(safe_stdev(d)) if d else float("nan")
        ingress = ingress_counts[c]
        drop_rate = (100.0 * unmatched_ingress[c] / ingress) if ingress > 0 else float("nan")

        results[c] = {
            "ingress_packets": float(ingress_counts[c]),
            "egress_packets": float(egress_counts[c]),
            "matched_packets": float(matched_counts[c]),
            "unmatched_ingress": float(unmatched_ingress[c]),
            "unmatched_egress": float(unmatched_egress[c]),
            "drop_rate_pct": drop_rate,
            "rst_ingress": float(rst_ingress[c]),
            "rst_egress": float(rst_egress[c]),
            "latency_mean_ms": lat_mean_ms,
            "latency_median_ms": lat_median_ms,
            "latency_p95_ms": lat_p95_ms,
            "latency_p99_ms": lat_p99_ms,
            "latency_std_ms": lat_std_ms,
        }
    return results


def discover_runs(input_dir: Path) -> Dict[int, Dict[str, Path]]:
    found: Dict[int, Dict[str, Path]] = defaultdict(dict)
    for run_dir in sorted(input_dir.glob("run_*")):
        if not run_dir.is_dir():
            continue
        suffix = run_dir.name.replace("run_", "")
        try:
            run_idx = int(suffix)
        except ValueError:
            continue
        for variant in ("forward", "extraction"):
            variant_dir = run_dir / variant
            ing = variant_dir / "s1_ingress.pcap"
            eg = variant_dir / "s1_egress.pcap"
            if ing.is_file() and eg.is_file():
                found[run_idx][variant] = variant_dir
    return dict(sorted(found.items()))


def ci95_for_deltas(deltas: List[float]) -> Tuple[float, float]:
    if len(deltas) < 2:
        return float("nan"), float("nan")
    mu = mean(deltas)
    sd = stdev(deltas)
    tcrit = t_critical_95(len(deltas) - 1)
    half = tcrit * (sd / math.sqrt(len(deltas)))
    return mu - half, mu + half


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


def main() -> None:
    parser = argparse.ArgumentParser(description="Analyze Maynard overhead runs")
    parser.add_argument("--input-dir", required=True, help="Root directory with run_XX/<variant>/ pcaps")
    parser.add_argument("--output-dir", default=None, help="Output directory (default: input-dir)")
    args = parser.parse_args()

    input_dir = Path(args.input_dir).resolve()
    output_dir = Path(args.output_dir).resolve() if args.output_dir else input_dir
    output_dir.mkdir(parents=True, exist_ok=True)

    runs = discover_runs(input_dir)
    if not runs:
        raise SystemExit(f"No valid run_XX/<variant>/s1_ingress|egress.pcap found in {input_dir}")

    per_run_rows: List[Dict[str, str]] = []
    per_run_values: Dict[int, Dict[str, Dict[str, Dict[str, float]]]] = defaultdict(lambda: defaultdict(dict))

    for run_idx, variants in runs.items():
        for variant, vdir in variants.items():
            pair = analyze_pair(vdir / "s1_ingress.pcap", vdir / "s1_egress.pcap")
            per_run_values[run_idx][variant] = pair
            for traffic_class in CLASSES:
                row: Dict[str, str] = {
                    "run_index": str(run_idx),
                    "variant": variant,
                    "traffic_class": traffic_class,
                }
                for metric in SUMMARY_METRICS:
                    row[metric] = fmt(pair[traffic_class][metric])
                per_run_rows.append(row)

    per_run_fieldnames = ["run_index", "variant", "traffic_class"] + list(SUMMARY_METRICS)
    write_csv(output_dir / "per_run.csv", per_run_rows, per_run_fieldnames)

    summary_rows: List[Dict[str, str]] = []
    for traffic_class in CLASSES:
        for metric in SUMMARY_METRICS:
            fw_vals: List[float] = []
            ex_vals: List[float] = []
            deltas: List[float] = []
            for run_idx in sorted(per_run_values.keys()):
                run_data = per_run_values[run_idx]
                if "forward" not in run_data or "extraction" not in run_data:
                    continue
                fw = run_data["forward"][traffic_class][metric]
                ex = run_data["extraction"][traffic_class][metric]
                if math.isnan(fw) or math.isnan(ex):
                    continue
                fw_vals.append(fw)
                ex_vals.append(ex)
                deltas.append(ex - fw)

            n_pairs = len(deltas)
            fw_mean = mean(fw_vals) if fw_vals else float("nan")
            ex_mean = mean(ex_vals) if ex_vals else float("nan")
            delta_abs = mean(deltas) if deltas else float("nan")
            delta_pct = (100.0 * delta_abs / fw_mean) if fw_vals and fw_mean != 0 else float("nan")
            ci_low, ci_high = ci95_for_deltas(deltas)

            summary_rows.append(
                {
                    "traffic_class": traffic_class,
                    "metric": metric,
                    "n_pairs": str(n_pairs),
                    "forward_mean": fmt(fw_mean),
                    "extraction_mean": fmt(ex_mean),
                    "delta_abs": fmt(delta_abs),
                    "delta_pct": fmt(delta_pct),
                    "ci95_low": fmt(ci_low),
                    "ci95_high": fmt(ci_high),
                }
            )

    summary_fieldnames = [
        "traffic_class",
        "metric",
        "n_pairs",
        "forward_mean",
        "extraction_mean",
        "delta_abs",
        "delta_pct",
        "ci95_low",
        "ci95_high",
    ]
    write_csv(output_dir / "summary.csv", summary_rows, summary_fieldnames)

    # Quality checks (paired runs only, class opcua_all_8666).
    quality_rows: List[List[str]] = []
    for run_idx in sorted(per_run_values.keys()):
        run_data = per_run_values[run_idx]
        if "forward" not in run_data or "extraction" not in run_data:
            quality_rows.append([str(run_idx), "missing variant", "n/a", "n/a", "n/a"])
            continue
        fw = run_data["forward"][CLASS_ALL]
        ex = run_data["extraction"][CLASS_ALL]
        same_ingress = "yes" if int(fw["ingress_packets"]) == int(ex["ingress_packets"]) else "no"
        drop_fw = fw["drop_rate_pct"]
        drop_ex = ex["drop_rate_pct"]
        rst_fw = int(fw["rst_ingress"]) + int(fw["rst_egress"])
        rst_ex = int(ex["rst_ingress"]) + int(ex["rst_egress"])
        quality_rows.append(
            [
                str(run_idx),
                same_ingress,
                fmt(drop_fw),
                fmt(drop_ex),
                f"{rst_fw}/{rst_ex}",
            ]
        )

    # Concise markdown report.
    now = datetime.now(timezone.utc).isoformat()
    lines: List[str] = []
    lines.append("# Maynard Overhead Report")
    lines.append("")
    lines.append(f"- Generated at: `{now}`")
    lines.append(f"- Input dir: `{input_dir}`")
    lines.append(f"- Runs discovered: `{len(runs)}`")
    lines.append("")
    lines.append("## Quality Checks (`opcua_all_8666`)")
    lines.append("")
    lines.append(
        markdown_table(
            ["run", "same_ingress_count", "drop_fw_pct", "drop_ex_pct", "rst_fw/rst_ex"],
            quality_rows,
        )
    )
    lines.append("")
    lines.append("## Summary (paired deltas, extraction - forward)")
    lines.append("")

    md_rows: List[List[str]] = []
    for row in summary_rows:
        if row["metric"] not in ("latency_mean_ms", "latency_p95_ms", "drop_rate_pct", "unmatched_ingress"):
            continue
        md_rows.append(
            [
                row["traffic_class"],
                row["metric"],
                row["n_pairs"],
                row["forward_mean"],
                row["extraction_mean"],
                row["delta_abs"],
                row["delta_pct"],
                f"[{row['ci95_low']}, {row['ci95_high']}]",
            ]
        )
    lines.append(
        markdown_table(
            [
                "class",
                "metric",
                "n_pairs",
                "forward",
                "extraction",
                "delta_abs",
                "delta_pct",
                "ci95",
            ],
            md_rows,
        )
    )
    lines.append("")
    lines.append("Artifacts:")
    lines.append("- `per_run.csv`")
    lines.append("- `summary.csv`")
    lines.append("- `report.md`")
    lines.append("")

    (output_dir / "report.md").write_text("\n".join(lines), encoding="utf-8")

    print(f"Generated: {output_dir / 'per_run.csv'}")
    print(f"Generated: {output_dir / 'summary.csv'}")
    print(f"Generated: {output_dir / 'report.md'}")


if __name__ == "__main__":
    main()
