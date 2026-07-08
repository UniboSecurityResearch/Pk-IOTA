#!/usr/bin/env python3
"""Common pcap parsing and switch-latency analysis helpers for testbeds."""

from __future__ import annotations

import hashlib
import math
import struct
from collections import defaultdict, deque
from dataclasses import dataclass
from pathlib import Path
from statistics import mean, median, stdev
from typing import Deque, Dict, Iterable, List, Optional, Sequence, Tuple


CLASS_OPN_CERT = "opcua_opn_cert"
CLASS_OPN_NO_CERT = "opcua_opn_no_cert"
CLASS_OTHER = "opcua_other"

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
    "negative_delay_matches",
)
SUMMARY_METRICS = LATENCY_METRICS + COUNT_METRICS


@dataclass(frozen=True)
class OpcuaOpnInfo:
    security_policy_uri: Optional[str]
    sender_certificate_length: Optional[int]
    receiver_thumbprint_length: Optional[int]
    receiver_thumbprint: Optional[bytes]

    @property
    def has_sender_certificate(self) -> bool:
        return self.sender_certificate_length is not None and self.sender_certificate_length > 0


@dataclass
class Packet:
    ts: float
    src_ip: str
    dst_ip: str
    src_port: int
    dst_port: int
    ip_id: int
    seq: int
    ack: int
    flags: int
    window: int
    tcp_checksum: int
    payload_digest: bytes
    payload: bytes

    @property
    def payload_len(self) -> int:
        return len(self.payload)

    @property
    def is_rst(self) -> bool:
        return bool(self.flags & 0x04)

    @property
    def key(self) -> Tuple[str, str, int, int, int, int, int, int, int, int, int, bytes]:
        return (
            self.src_ip,
            self.dst_ip,
            self.src_port,
            self.dst_port,
            self.ip_id,
            self.seq,
            self.ack,
            self.flags,
            self.window,
            self.tcp_checksum,
            self.payload_len,
            self.payload_digest,
        )


def class_all(port: int) -> str:
    return f"opcua_all_{port}"


def classes_for_port(port: int) -> Tuple[str, str, str, str]:
    return (CLASS_OPN_CERT, CLASS_OPN_NO_CERT, CLASS_OTHER, class_all(port))


def quantile_sorted(values: List[float], q: float) -> float:
    if not values:
        return float("nan")
    idx = int(math.ceil(q * len(values))) - 1
    idx = max(0, min(idx, len(values) - 1))
    return values[idx]


def ms(value_s: float) -> float:
    return value_s * 1000.0


def safe_mean(values: List[float]) -> float:
    return mean(values) if values else float("nan")


def safe_stdev(values: List[float]) -> float:
    return stdev(values) if len(values) > 1 else float("nan")


def t_critical_95(df: int) -> float:
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


def ci95_for_deltas(deltas: List[float]) -> Tuple[float, float]:
    if len(deltas) < 2:
        return float("nan"), float("nan")
    mu = mean(deltas)
    sd = stdev(deltas)
    half = t_critical_95(len(deltas) - 1) * (sd / math.sqrt(len(deltas)))
    return mu - half, mu + half


def fmt(value: float) -> str:
    if value is None or isinstance(value, float) and (math.isnan(value) or math.isinf(value)):
        return "nan"
    return f"{value:.6f}"


def iter_pcap(path: Path) -> Iterable[Tuple[float, bytes]]:
    with path.open("rb") as f:
        header = f.read(24)
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
            return

        ph_struct = struct.Struct(f"{endian}IIII")
        while True:
            ph = f.read(16)
            if not ph or len(ph) < 16:
                break
            ts_sec, ts_frac, incl_len, _orig_len = ph_struct.unpack(ph)
            data = f.read(incl_len)
            if len(data) < incl_len:
                break
            yield ts_sec + (ts_frac * ts_scale), data


def parse_ipv4_tcp(ts: float, frame: bytes) -> Optional[Packet]:
    if len(frame) < 14:
        return None

    offset = 14
    ethertype = struct.unpack("!H", frame[12:14])[0]
    if ethertype == 0x8100 and len(frame) >= 18:
        ethertype = struct.unpack("!H", frame[16:18])[0]
        offset = 18

    if ethertype != 0x0800 or len(frame) < offset + 20:
        return None

    ver_ihl = frame[offset]
    version = ver_ihl >> 4
    ihl = (ver_ihl & 0x0F) * 4
    if version != 4 or ihl < 20 or len(frame) < offset + ihl:
        return None

    total_len = struct.unpack("!H", frame[offset + 2 : offset + 4])[0]
    ip_id = struct.unpack("!H", frame[offset + 4 : offset + 6])[0]
    if frame[offset + 9] != 6:
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
    window = struct.unpack("!H", frame[tcp_off + 14 : tcp_off + 16])[0]
    tcp_checksum = struct.unpack("!H", frame[tcp_off + 16 : tcp_off + 18])[0]

    ip_end = offset + total_len
    cap_end = min(len(frame), ip_end)
    payload_start = tcp_off + data_off
    payload = b"" if payload_start > cap_end else frame[payload_start:cap_end]
    payload_digest = hashlib.blake2b(payload, digest_size=8).digest()

    return Packet(
        ts=ts,
        src_ip=src_ip,
        dst_ip=dst_ip,
        src_port=src_port,
        dst_port=dst_port,
        ip_id=ip_id,
        seq=seq,
        ack=ack,
        flags=flags,
        window=window,
        tcp_checksum=tcp_checksum,
        payload_digest=payload_digest,
        payload=payload,
    )


def parse_opn(payload: bytes) -> Optional[OpcuaOpnInfo]:
    if len(payload) < 16 or not payload.startswith(b"OPN"):
        return None

    off = 8 + 4  # OPC UA message header + secureChannelId.
    if len(payload) < off + 4:
        return OpcuaOpnInfo(None, None, None, None)

    policy_len = struct.unpack_from("<i", payload, off)[0]
    off += 4
    policy_uri: Optional[str] = None
    if policy_len >= 0:
        if len(payload) < off + policy_len:
            return OpcuaOpnInfo(None, None, None, None)
        policy_uri = payload[off : off + policy_len].decode("utf-8", errors="replace")
        off += policy_len

    if len(payload) < off + 4:
        return OpcuaOpnInfo(policy_uri, None, None, None)

    cert_len = struct.unpack_from("<i", payload, off)[0]
    off += 4
    if cert_len >= 0:
        off += cert_len

    thumb_len: Optional[int] = None
    thumb: Optional[bytes] = None
    if len(payload) >= off + 4:
        thumb_len = struct.unpack_from("<i", payload, off)[0]
        off += 4
        if thumb_len > 0 and len(payload) >= off + thumb_len:
            thumb = payload[off : off + thumb_len]

    return OpcuaOpnInfo(policy_uri, cert_len, thumb_len, thumb)


def packet_classes(pkt: Packet, port: int) -> List[str]:
    out = [class_all(port)]
    if pkt.payload_len == 0:
        return out
    opn = parse_opn(pkt.payload)
    if opn is not None:
        out.append(CLASS_OPN_CERT if opn.has_sender_certificate else CLASS_OPN_NO_CERT)
    else:
        out.append(CLASS_OTHER)
    return out


def iter_port_packets(pcaps: Sequence[Path], port: int) -> Iterable[Packet]:
    for pcap in pcaps:
        for ts, frame in iter_pcap(pcap):
            pkt = parse_ipv4_tcp(ts, frame)
            if pkt is None:
                continue
            if pkt.src_port != port and pkt.dst_port != port:
                continue
            yield pkt


def ingress_fingerprint(pcaps: Sequence[Path], port: int) -> str:
    h = hashlib.sha256()
    count = 0
    for pkt in sorted(iter_port_packets(pcaps, port), key=lambda p: p.key):
        count += 1
        h.update(repr(pkt.key).encode("utf-8"))
        h.update(b"\n")
    return f"{count}:{h.hexdigest()}"


def extract_receiver_thumbprints(pcaps: Sequence[Path], port: int) -> List[str]:
    out = set()
    for pkt in iter_port_packets(pcaps, port):
        opn = parse_opn(pkt.payload)
        if opn is not None and opn.receiver_thumbprint:
            out.add("0x" + opn.receiver_thumbprint.hex())
    return sorted(out)


def analyze_paths(ingress_pcaps: Sequence[Path], egress_pcaps: Sequence[Path], port: int) -> Dict[str, Dict[str, float]]:
    classes = classes_for_port(port)
    ingress_q: Dict[
        Tuple[str, str, int, int, int, int, int, int, int, int, int, bytes],
        Deque[Tuple[float, List[str]]],
    ] = defaultdict(deque)
    delays_by_class: Dict[str, List[float]] = {c: [] for c in classes}
    ingress_counts = {c: 0 for c in classes}
    egress_counts = {c: 0 for c in classes}
    matched_counts = {c: 0 for c in classes}
    unmatched_ingress = {c: 0 for c in classes}
    unmatched_egress = {c: 0 for c in classes}
    rst_ingress = {c: 0 for c in classes}
    rst_egress = {c: 0 for c in classes}
    negative_delay_matches = {c: 0 for c in classes}

    ingress_events = sorted(iter_port_packets(ingress_pcaps, port), key=lambda p: p.ts)
    egress_events = sorted(iter_port_packets(egress_pcaps, port), key=lambda p: p.ts)

    for pkt in ingress_events:
        cls = packet_classes(pkt, port)
        for c in cls:
            ingress_counts[c] += 1
            if pkt.is_rst:
                rst_ingress[c] += 1
        ingress_q[pkt.key].append((pkt.ts, cls))

    for pkt in egress_events:
        cls = packet_classes(pkt, port)
        for c in cls:
            egress_counts[c] += 1
            if pkt.is_rst:
                rst_egress[c] += 1

        queue = ingress_q.get(pkt.key)
        if queue and len(queue) > 0:
            ts_in, cls_in = queue[0]
            queue.popleft()
            delay = pkt.ts - ts_in
            for c in cls_in:
                matched_counts[c] += 1
            if delay >= 0:
                for c in cls_in:
                    delays_by_class[c].append(delay)
            else:
                for c in cls_in:
                    negative_delay_matches[c] += 1
        else:
            for c in cls:
                unmatched_egress[c] += 1

    for queue in ingress_q.values():
        while queue:
            _ts_in, cls_in = queue.popleft()
            for c in cls_in:
                unmatched_ingress[c] += 1

    results: Dict[str, Dict[str, float]] = {}
    for c in classes:
        d = sorted(delays_by_class[c])
        ingress = ingress_counts[c]
        results[c] = {
            "ingress_packets": float(ingress_counts[c]),
            "egress_packets": float(egress_counts[c]),
            "matched_packets": float(matched_counts[c]),
            "unmatched_ingress": float(unmatched_ingress[c]),
            "unmatched_egress": float(unmatched_egress[c]),
            "drop_rate_pct": (100.0 * unmatched_ingress[c] / ingress) if ingress > 0 else float("nan"),
            "rst_ingress": float(rst_ingress[c]),
            "rst_egress": float(rst_egress[c]),
            "negative_delay_matches": float(negative_delay_matches[c]),
            "latency_mean_ms": ms(safe_mean(d)) if d else float("nan"),
            "latency_median_ms": ms(median(d)) if d else float("nan"),
            "latency_p95_ms": ms(quantile_sorted(d, 0.95)) if d else float("nan"),
            "latency_p99_ms": ms(quantile_sorted(d, 0.99)) if d else float("nan"),
            "latency_std_ms": ms(safe_stdev(d)) if d else float("nan"),
        }
    return results
