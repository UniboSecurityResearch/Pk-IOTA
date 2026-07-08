# OT Security Testbed (Kathara + P4)

This lab reproduces the original `ot-security-testbed/docker-compose.yml` inside Kathara for overhead measurements between:
- `forward.p4` (baseline), and
- `opcua_extraction.p4` (Pk-IOTA extraction/validation pipeline).

Because the original setup uses a single Docker network (`net-testbed`), the Kathara reproduction uses one P4 switch (`s1`) that connects all services.

## Topology and Services

### Network model
- One L2 segment
- One P4 switch: `s1`
- OPC UA traffic class measured: TCP/4840

### Mapped services
- `telegraf`
- `influxdb`
- `chronograf`
- `kapacitor`
- `industrial_process`
- `openplc`
- `fuxa`
- `attacker`
- `shellinabox`

## Important Files
- `lab.conf`: device graph and image tags
- `set_p4_variant.sh`: activates `forward` or `extraction`
- `run_otsec_overhead.sh`: campaign runner
- `analyze_otsec_overhead.py`: post-processing and report generation
- `build_kathara_images.sh`: builds base and `*:kathara-net` wrapper images

## Prerequisites
- Docker
- Kathara
- Python 3
- `capinfos` (`wireshark-common`)

## 1) Build Certificates and Images

From repository root:
```bash
cd testbeds/ot-security-testbed/certificates
./create-certs.sh

cd ../kathara-otsec-p4
./build_kathara_images.sh
```

If `run_otsec_overhead.sh` reports missing images, rebuild before running the campaign.

## 2) Select P4 Variant (Manual Check)
```bash
cd testbeds/ot-security-testbed/kathara-otsec-p4
./set_p4_variant.sh ip_forward
# or
./set_p4_variant.sh opcua_forward
# or
./set_p4_variant.sh extraction
```

## 3) Run Overhead Collection

### Smoke
```bash
./run_otsec_overhead.sh \
  --runs 1 \
  --variant all \
  --duration-sec 120 \
  --warmup-sec 10 \
  --stimulate \
  --out-dir ../../../tests/TESTBEDS/otsec_overhead_smoke
```

### Main campaign
```bash
./run_otsec_overhead.sh \
  --runs 3 \
  --variant all \
  --duration-sec 14400 \
  --warmup-sec 30 \
  --stimulate \
  --out-dir ../../../tests/TESTBEDS/otsec_overhead_main
```

## 4) Analyze Results
```bash
python3 ./analyze_otsec_overhead.py \
  --input-dir ../../../tests/TESTBEDS/otsec_overhead_main \
  --output-dir ../../../tests/TESTBEDS/otsec_overhead_main \
  --require-extraction-opn-cert
```

Generated artifacts:
- `per_run.csv`
- `summary.csv`
- `quality.csv`
- `report.md`

## Output Layout
- `run_XX/ip_forward/*.pcap`
- `run_XX/opcua_forward/*.pcap`
- `run_XX/extraction/*.pcap`
- `run_XX/<variant>/metadata.env`
- `run_XX/<variant>/s1.log`

## Troubleshooting
- `Missing Docker images required by this lab`:
  - run `./build_kathara_images.sh` again from this directory.
- Empty or invalid captures:
  - increase `--warmup-sec` and verify service startup stability.
- Very long executions:
  - use smoke settings first to validate pipeline end-to-end.

## Security Note
This lab includes test credentials and attack-side tooling by design. Keep it isolated and do not reuse these credentials outside controlled environments.
