#!/usr/bin/env python3
"""Print OPC UA receiver thumbprints found in one or more pcap files."""

from __future__ import annotations

import argparse
from pathlib import Path

from common_pcap_analysis import extract_receiver_thumbprints


def main() -> None:
    parser = argparse.ArgumentParser(description="Extract OPC UA OPN receiver thumbprints from pcaps")
    parser.add_argument("--port", type=int, required=True)
    parser.add_argument("pcaps", nargs="+")
    args = parser.parse_args()

    paths = [Path(p) for p in args.pcaps]
    for thumb in extract_receiver_thumbprints(paths, args.port):
        print(thumb)


if __name__ == "__main__":
    main()
