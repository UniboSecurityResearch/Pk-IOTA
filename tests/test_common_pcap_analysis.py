import struct
import sys
import tempfile
import unittest
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
sys.path.insert(0, str(ROOT / "testbeds"))

from common_pcap_analysis import (  # noqa: E402
    CLASS_OPN_CERT,
    CLASS_OPN_NO_CERT,
    analyze_paths,
    class_all,
    extract_receiver_thumbprints,
    ingress_fingerprint,
    parse_opn,
)


def opn_payload(cert=b"", thumb=b"\x11" * 20):
    policy = b"http://opcfoundation.org/UA/SecurityPolicy#Basic256Sha256"
    body = (
        struct.pack("<I", 1)
        + struct.pack("<i", len(policy))
        + policy
        + struct.pack("<i", len(cert))
        + cert
        + struct.pack("<i", len(thumb))
        + thumb
    )
    return b"OPNF" + struct.pack("<I", len(body) + 8) + body


def opn_no_cert_payload():
    policy = b"http://opcfoundation.org/UA/SecurityPolicy#None"
    body = struct.pack("<I", 1) + struct.pack("<i", len(policy)) + policy + struct.pack("<i", -1)
    return b"OPNF" + struct.pack("<I", len(body) + 8) + body


def tcp_frame(payload, *, ts_id=1, flags=0x18, data_offset_words=5):
    src_ip = b"\x0a\x00\x00\x01"
    dst_ip = b"\x0a\x00\x00\x02"
    options = b"\x01" * ((data_offset_words - 5) * 4)
    tcp_header = (
        struct.pack("!HHII", 12345, 4840, 1000 + ts_id, 2000 + ts_id)
        + bytes([(data_offset_words << 4), flags])
        + struct.pack("!HHH", 8192, 0x1234, 0)
        + options
    )
    total_len = 20 + len(tcp_header) + len(payload)
    ip_header = (
        b"\x45\x00"
        + struct.pack("!H", total_len)
        + struct.pack("!H", ts_id)
        + b"\x00\x00\x40\x06\x00\x00"
        + src_ip
        + dst_ip
    )
    eth = b"\xaa\xbb\xcc\xdd\xee\xff\x00\x11\x22\x33\x44\x55\x08\x00"
    return eth + ip_header + tcp_header + payload


def write_pcap(path, events):
    with path.open("wb") as f:
        f.write(struct.pack("<IHHIIII", 0xA1B2C3D4, 2, 4, 0, 0, 65535, 1))
        for ts, frame in events:
            sec = int(ts)
            usec = int((ts - sec) * 1_000_000)
            f.write(struct.pack("<IIII", sec, usec, len(frame), len(frame)))
            f.write(frame)


class CommonPcapAnalysisTests(unittest.TestCase):
    def test_parse_opn_cert_and_no_cert(self):
        cert_info = parse_opn(opn_payload(cert=b"abc"))
        self.assertIsNotNone(cert_info)
        self.assertTrue(cert_info.has_sender_certificate)
        self.assertEqual(cert_info.receiver_thumbprint, b"\x11" * 20)

        no_cert_info = parse_opn(opn_no_cert_payload())
        self.assertIsNotNone(no_cert_info)
        self.assertFalse(no_cert_info.has_sender_certificate)
        self.assertEqual(no_cert_info.sender_certificate_length, -1)

    def test_matching_rst_and_negative_delay_quality(self):
        with tempfile.TemporaryDirectory() as td:
            ingress = Path(td) / "ingress.pcap"
            egress = Path(td) / "egress.pcap"
            normal = tcp_frame(b"hello", ts_id=1)
            negative = tcp_frame(opn_payload(cert=b"abc"), ts_id=2)
            rst = tcp_frame(b"", ts_id=3, flags=0x04)
            write_pcap(ingress, [(1.0, normal), (3.0, negative), (4.0, rst)])
            write_pcap(egress, [(1.1, normal), (2.5, negative), (4.1, rst)])

            result = analyze_paths((ingress,), (egress,), 4840)
            all_values = result[class_all(4840)]
            self.assertEqual(all_values["ingress_packets"], 3.0)
            self.assertEqual(all_values["egress_packets"], 3.0)
            self.assertEqual(all_values["matched_packets"], 3.0)
            self.assertEqual(all_values["unmatched_ingress"], 0.0)
            self.assertEqual(all_values["unmatched_egress"], 0.0)
            self.assertEqual(all_values["negative_delay_matches"], 1.0)
            self.assertEqual(all_values["rst_ingress"], 1.0)
            self.assertEqual(all_values["rst_egress"], 1.0)
            self.assertEqual(result[CLASS_OPN_CERT]["ingress_packets"], 1.0)
            self.assertEqual(result[CLASS_OPN_CERT]["matched_packets"], 1.0)
            self.assertEqual(result[CLASS_OPN_CERT]["negative_delay_matches"], 1.0)

    def test_thumbprint_extraction_and_tcp_options(self):
        with tempfile.TemporaryDirectory() as td:
            pcap = Path(td) / "trace.pcap"
            thumb = bytes.fromhex("00112233445566778899aabbccddeeff00112233")
            frame = tcp_frame(opn_payload(cert=b"abc", thumb=thumb), ts_id=7, data_offset_words=8)
            write_pcap(pcap, [(1.0, frame)])

            self.assertEqual(extract_receiver_thumbprints((pcap,), 4840), ["0x" + thumb.hex()])

            no_cert = parse_opn(opn_no_cert_payload())
            self.assertEqual(CLASS_OPN_NO_CERT, "opcua_opn_no_cert")
            self.assertFalse(no_cert.has_sender_certificate)

    def test_ingress_fingerprint_ignores_capture_order(self):
        with tempfile.TemporaryDirectory() as td:
            first = Path(td) / "first.pcap"
            second = Path(td) / "second.pcap"
            pkt_a = tcp_frame(b"alpha", ts_id=11)
            pkt_b = tcp_frame(b"bravo", ts_id=12)
            write_pcap(first, [(1.0, pkt_a), (2.0, pkt_b)])
            write_pcap(second, [(1.0, pkt_b), (2.0, pkt_a)])

            self.assertEqual(ingress_fingerprint((first,), 4840), ingress_fingerprint((second,), 4840))


if __name__ == "__main__":
    unittest.main()
