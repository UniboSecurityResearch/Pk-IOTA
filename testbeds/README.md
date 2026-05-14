# Testbeds Guide

This document explains the available testbeds, required images, and the exact commands to run overhead measurements locally.

## Available Testbeds
- `Maynard`
  - Replay-based campaign on host-split PCAP traces.
  - Main traffic focus: OPC UA over TCP/8666.
- `MOTRA` (`motra/simple-water-treatment-plant/kathara-single-dev-p4`)
  - Industrial water-treatment scenario reproduced in Kathara.
  - One P4 switch per subnet.
  - Main traffic focus: OPC UA over TCP/4840.
- `OTSEC` (`ot-security-testbed/kathara-otsec-p4`)
  - OT security scenario reproduced in Kathara.
  - Single L2 domain with one P4 switch.
  - Main traffic focus: OPC UA over TCP/4840.
- `1client_1server`
  - Controlled client/server setup for certificate-size overhead sweeps.

## Shared Tooling in `testbeds/`
- `run.sh`
  - All-in-one orchestrator (name is historical; it works for local execution too).
- `publish_multiarch_images.sh`
  - Builds and pushes multi-arch images (`amd64`, `arm64`).
- `set_lab_images.sh`
  - Rewrites `lab.conf` image tags for lab portability.
- `images/`
  - Canonical Dockerfiles used by testbeds.

## Dockerfiles in `testbeds/images`
- `tcpreplay/`: minimal replay host image for Maynard.
- `asyncua/`: minimal OPC UA host image for deterministic baseline tests.
- `asyncua-toolbox/`: extended diagnostics image (`asyncua`, `cryptography`, `iperf3`, `hping3`, `tshark`).

Use `asyncua-toolbox` when you need troubleshooting/traffic inspection. Use `asyncua` for lean, reproducible performance runs.

## Prerequisites
- Docker
- Kathara
- Python 3
- `capinfos` (`wireshark-common`)
- Optional for formal checks: `tamarin-prover`, `maude`

## Default Results Path
When using `run.sh` without `--results-dir`, outputs are written to:
- `tests/TESTBEDS`

---

## 1) Maynard
```bash
cd testbeds/Maynard
./run_maynard_overhead.sh \
  --runs 10 \
  --variant both \
  --start-timeout 300 \
  --timeout 21600 \
  --out-dir ../../tests/TESTBEDS/maynard_overhead_main

python3 ./analyze_maynard_overhead.py \
  --input-dir ../../tests/TESTBEDS/maynard_overhead_main \
  --output-dir ../../tests/TESTBEDS/maynard_overhead_main
```

## 2) MOTRA

Build base images first (from `single-dev` compose flow), then build wrappers:
```bash
cd testbeds/motra/simple-water-treatment-plant/kathara-single-dev-p4
./build_kathara_images.sh
```

Run and analyze:
```bash
./run_motra_overhead.sh \
  --runs 3 \
  --variant both \
  --duration-sec 14400 \
  --warmup-sec 30 \
  --out-dir ../../../../tests/TESTBEDS/motra_overhead_main

python3 ./analyze_motra_overhead.py \
  --input-dir ../../../../tests/TESTBEDS/motra_overhead_main \
  --output-dir ../../../../tests/TESTBEDS/motra_overhead_main
```

## 3) OTSEC
Detailed lab-specific notes are available here:
- [ot-security-testbed/kathara-otsec-p4/README.md](ot-security-testbed/kathara-otsec-p4/README.md)

Quick commands:
```bash
cd testbeds/ot-security-testbed/certificates
./create-certs.sh

cd ../kathara-otsec-p4
./build_kathara_images.sh

./run_otsec_overhead.sh \
  --runs 3 \
  --variant both \
  --duration-sec 14400 \
  --warmup-sec 30 \
  --out-dir ../../../tests/TESTBEDS/otsec_overhead_main

python3 ./analyze_otsec_overhead.py \
  --input-dir ../../../tests/TESTBEDS/otsec_overhead_main \
  --output-dir ../../../tests/TESTBEDS/otsec_overhead_main
```

## 4) 1client_1server Certificate-Size Sweep
```bash
cd testbeds/1client_1server
./run_cert_size_overhead.sh \
  --runs 3 \
  --variant both \
  --key-bits-list 1024,2048,3072,4096 \
  --sessions 30 \
  --session-timeout 60 \
  --warmup-sec 20 \
  --mtu 9000 \
  --out-dir ../../tests/TESTBEDS/cert_size_overhead_main

python3 ./analyze_cert_size_overhead.py \
  --input-dir ../../tests/TESTBEDS/cert_size_overhead_main \
  --output-dir ../../tests/TESTBEDS/cert_size_overhead_main
```

---

## One-Command Execution (All Testbeds)
```bash
./testbeds/run.sh --root "$PWD" --profile main --tag main
```

Smoke run:
```bash
./testbeds/run.sh --root "$PWD" --profile smoke --tag smoke
```

## Optional: Publish Multi-Arch Images
```bash
docker login
./testbeds/publish_multiarch_images.sh --root "$PWD" --dockerhub-user <user> --tag v1
```

Then rewrite `lab.conf` references:
```bash
./testbeds/set_lab_images.sh --root "$PWD" --dockerhub-user <user> --tag v1 --include-motra --include-otsec
```
