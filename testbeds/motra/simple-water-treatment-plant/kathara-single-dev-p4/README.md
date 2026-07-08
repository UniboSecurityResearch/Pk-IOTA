# SWaT Single-Dev on Kathara with 4 P4 switches

This lab reproduces the Docker Compose topology in:
`simple-water-treatment-plant/single-dev/compose.yml`

Each Compose network is mapped to one P4 switch:
- `it-net` -> `s_it`
- `plc-net` -> `s_plc`
- `ot-net` -> `s_ot`
- `levelsensor-net` -> `s_lsensor`

## Topology mapping

Services (Kathara device -> Compose service):
- `headunit_dashboard` -> `headunit-dashboard`
- `plc_server` -> `plc-server`
- `plc_historian` -> `plc-historian`
- `plc_logic` -> `plc-logic`
- `levelsensor_server` -> `levelsensor-server`
- `water_tank_simulation` -> `water-tank-simulation`
- `valve_server` -> `valve-server`

## IP plan

- it-net: `10.10.10.0/24`
  - headunit_dashboard: `10.10.10.11`
  - plc_server(eth0): `10.10.10.12`
- plc-net: `10.10.20.0/24`
  - plc_server(eth1): `10.10.20.11`
  - plc_historian: `10.10.20.12`
  - plc_logic(eth0): `10.10.20.13`
- ot-net: `10.10.30.0/24`
  - plc_logic(eth1): `10.10.30.11`
  - levelsensor_server(eth0): `10.10.30.12`
  - valve_server: `10.10.30.13`
- levelsensor-net: `10.10.40.0/24`
  - levelsensor_server(eth1): `10.10.40.11`
  - water_tank_simulation: `10.10.40.12`

## P4 variants

The switches compile `active.p4`.
Use:

```bash
./set_p4_variant.sh forward
# or
./set_p4_variant.sh extraction
```

## Run

```bash
cd testbeds/motra/simple-water-treatment-plant/kathara-single-dev-p4
./build_kathara_images.sh
kathara lstart --noterminals
```

Startup behavior:
- Endpoint images are secure wrappers (`*:kathara-net`) built from the original MOTRA images with `iproute2`, patched app files, and a shared OPC UA PKI.
- Compose-equivalent and OPC UA security environment variables are set in `lab.conf` via `device[env]`.

Stop:

```bash
kathara lclean
```

## Overhead benchmark

Collect comparable runs (`ip_forward`, `opcua_forward`, then `extraction`):

```bash
./run_motra_overhead.sh --runs 3 --variant all --duration-sec 3600 --warmup-sec 30 --out-dir ./overhead_runs_main
```

Analyze:

```bash
python3 ./analyze_motra_overhead.py --input-dir ./overhead_runs_main --require-extraction-opn-cert
```

Recommended campaign:
- Smoke: `--runs 1 --duration-sec 120`
- Main: `--runs 3 --duration-sec 3600`
- Extended (paper appendix): `--runs 5+` with longer duration if needed

## Quick connectivity checks

Inside the lab directory:

```bash
kathara exec headunit_dashboard ping -c 3 10.10.10.12
kathara exec plc_historian ping -c 3 10.10.20.13
kathara exec plc_logic ping -c 3 10.10.30.13
kathara exec water_tank_simulation ping -c 3 10.10.40.11
```

## Notes

- This is a network-level reproduction of the Compose topology with one P4 switch per original Docker network.
- Switch commands program L2 forwarding (`dmac_forward`); extraction runs also program allowed OPC UA receiver thumbprints.
