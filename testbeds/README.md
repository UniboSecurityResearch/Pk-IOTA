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
  - All-in-one orchestrator for local campaigns.
  - It checks required images from each `lab.conf`; use `--build-motra` and `--build-otsec` when local secure wrapper images are missing.
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

## Deploying on a New Server (read before running campaigns)
1. **Jumbo frames.** The cert-size campaign (and any extraction run with
   certificates larger than ~1.3 KB) needs jumbo frames end-to-end: the P4
   parser has no TCP reassembly, so the whole OPN message including the
   certificate must fit in ONE frame. Container MTU alone is not enough — the
   Kathara collision-domain fabric must pass jumbo frames (the VDE network
   plugin does; the Linux-bridge plugin typically drops them). The cert-size
   runner verifies the jumbo path with a DF ping and fails fast with a
   diagnostic.
2. **Locally-built images.** MOTRA (`*:kathara-net`) and OTSEC
   (`telegraf:kathara-net`, `ot-*:kathara-net`) images are NOT pullable: run
   `./build_kathara_images.sh` in each lab on the target machine (OTSEC also
   requires `certificates/create-certs.sh` FIRST — certs are baked into the
   images; regenerating certs without rebuilding desynchronizes the P4
   thumbprint table from the wire).
   Kathara keeps the image ENTRYPOINT as PID1 (it only overrides the CMD): the
   OTSEC wrappers therefore reset it (`ENTRYPOINT []`) and services are
   launched by the `.startup` scripts after network configuration. If openplc/
   telegraf/industrial_process containers show `Exited (1)` right after
   lstart, you are running wrapper images built BEFORE this fix — rebuild.
3. **Never add `--log-console` to the measurement switches.** Per-packet debug
   logging slows BMv2 enough to drop packets at its receive socket under
   replay load and contaminates the latency measurements.
4. **Smoke first.** Validate with `./testbeds/run.sh --profile smoke` before
   the multi-hour main profile; smoke enables `--fail-on-quality`.
5. **Failures are isolated.** Runners record failed runs in
   `<out-dir>/failed_runs.txt` and continue; `run.sh` runs all requested
   campaigns and reports `COMPLETED WITH FAILURES` at the end.

## Default Results Path
When using `run.sh` without `--results-dir`, outputs are written to:
- `tests/TESTBEDS`

---

## 1) Maynard
```bash
cd testbeds/Maynard
./run_maynard_overhead.sh \
  --runs 10 \
  --variant all \
  --start-timeout 300 \
  --timeout 21600 \
  --out-dir ../../tests/TESTBEDS/maynard_overhead_main

python3 ./analyze_maynard_overhead.py \
  --input-dir ../../tests/TESTBEDS/maynard_overhead_main \
  --output-dir ../../tests/TESTBEDS/maynard_overhead_main \
  --require-same-ingress
```

## 2) MOTRA

Build secure wrapper images first:
```bash
cd testbeds/motra/simple-water-treatment-plant/kathara-single-dev-p4
./build_kathara_images.sh
```

Run and analyze:
```bash
./run_motra_overhead.sh \
  --runs 3 \
  --variant all \
  --duration-sec 14400 \
  --warmup-sec 30 \
  --out-dir ../../../../tests/TESTBEDS/motra_overhead_main

python3 ./analyze_motra_overhead.py \
  --input-dir ../../../../tests/TESTBEDS/motra_overhead_main \
  --output-dir ../../../../tests/TESTBEDS/motra_overhead_main \
  --require-extraction-opn-cert
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
  --variant all \
  --duration-sec 14400 \
  --warmup-sec 30 \
  --stimulate \
  --diagnostics on-failure \
  --out-dir ../../../tests/TESTBEDS/otsec_overhead_main

python3 ./analyze_otsec_overhead.py \
  --input-dir ../../../tests/TESTBEDS/otsec_overhead_main \
  --output-dir ../../../tests/TESTBEDS/otsec_overhead_main \
  --require-extraction-opn-cert
```

## 4) 1client_1server Certificate-Size Sweep
```bash
cd testbeds/1client_1server
./run_cert_size_overhead.sh \
  --runs 3 \
  --variant all \
  --key-bits-list 1024,2048,3072,4096 \
  --sessions 30 \
  --session-timeout 60 \
  --warmup-sec 20 \
  --mtu 9000 \
  --out-dir ../../tests/TESTBEDS/cert_size_overhead_main

python3 ./analyze_cert_size_overhead.py \
  --input-dir ../../tests/TESTBEDS/cert_size_overhead_main \
  --output-dir ../../tests/TESTBEDS/cert_size_overhead_main \
  --require-extraction-opn-cert
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

Enable local image builds only when needed:
```bash
./testbeds/run.sh --root "$PWD" --profile smoke --build-motra --build-otsec
```

## Optional: Publish Multi-Arch Images
```bash
docker login
./testbeds/publish_multiarch_images.sh --root "$PWD" --dockerhub-user <user> --tag v1
```

Image tags are explicit. Docker Hub does not automatically create `latest` when you push `v1`, so the runners and lab files use versioned tags such as `loriringhio97/tcpreplay:v1` and `loriringhio97/asyncua:v1`.

The publish script now skips already published tags by default and does not build base images unless explicitly requested:
```bash
./testbeds/publish_multiarch_images.sh --root "$PWD" --dockerhub-user <user> --tag v1 --with-base --with-otsec-base --with-motra-base
```

Then rewrite `lab.conf` references:
```bash
./testbeds/set_lab_images.sh --root "$PWD" --dockerhub-user <user> --tag v1 --include-motra --include-otsec
```
