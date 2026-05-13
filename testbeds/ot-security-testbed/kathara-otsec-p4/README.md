# OT Security Testbed on Kathara with P4

This lab reproduces `ot-security-testbed/docker-compose.yml` in Kathara.
The original Compose has one Docker network (`net-testbed`), therefore this reproduction uses one P4 switch (`s1`).

## Services mapped in Kathara

- `telegraf`
- `influxdb`
- `chronograf`
- `kapacitor`
- `industrial_process`
- `openplc`
- `fuxa`
- `attacker`
- `shellinabox`

All services are attached to a single L2 domain through `s1`.

## Build images

```bash
cd testbeds/ot-security-testbed/kathara-otsec-p4
./build_kathara_images.sh
```

This script builds base images for services that are `build:` in Compose, then creates `*:kathara-net` wrapper images with `iproute2`.
If you need certificate-based behavior from the original testbed, generate certs first from `../certificates/create-certs.sh`.

## P4 variants

```bash
./set_p4_variant.sh forward
# or
./set_p4_variant.sh extraction
```

## Start/stop lab

```bash
kathara lstart --noterminals -d .
kathara linfo -d .
kathara lclean -d .
```

## Overhead benchmark

Smoke:

```bash
./run_otsec_overhead.sh --runs 1 --variant both --duration-sec 120 --warmup-sec 10 --out-dir ./overhead_smoke
python3 ./analyze_otsec_overhead.py --input-dir ./overhead_smoke
```

Main campaign:

```bash
./run_otsec_overhead.sh --runs 3 --variant both --duration-sec 3600 --warmup-sec 30 --out-dir ./overhead_main
python3 ./analyze_otsec_overhead.py --input-dir ./overhead_main
```
