<!--
    Copyright (C) 2025 Lorenzo Rinieri, Giacomo Gori

    This program is free software: you can redistribute it and/or modify
    it under the terms of the GNU General Public License as published by
    the Free Software Foundation, either version 3 of the License, or
    (at your option) any later version.

    This program is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
    GNU General Public License for more details.

    You should have received a copy of the GNU General Public License
    along with this program.  If not, see <https://www.gnu.org/licenses/>.
-->
# Pk-IOTA

Pk-IOTA is a research prototype for securing OPC UA communications in Industry 4.0 by combining:
- programmable data-plane validation (P4 switches), and
- decentralized certificate management workflows built on IOTA.

This repository contains both the implementation and the reproducibility artifacts used for overhead evaluation and formal analysis.

## What Is In This Repository

### Top-level layout
- `IOTA_src/`
  - IOTA transaction workflows, smart contracts, frontend utilities, and MQTT-related scripts.
- `testbeds/`
  - Kathara-based network labs, P4 programs, traffic replay/synthesis pipelines, analyzers, and image build tooling.
- `tests/`
  - Result artifacts and plots (existing `IOTA`, `P4` and testbed campaign outputs under `TESTBEDS`).
- `formal_verification/`
  - Tamarin models and security property checks.
- `utils/`
  - Legacy helper scripts and utility image definitions.

### Testbeds currently maintained
- `testbeds/Maynard`
  - Replay-based benchmark using host-split PCAP traces (OPC UA on TCP/8666).
- `testbeds/motra/simple-water-treatment-plant/kathara-single-dev-p4`
  - MOTRA reproduction in Kathara with one P4 switch per subnet.
- `testbeds/ot-security-testbed/kathara-otsec-p4`
  - OT Security testbed reproduction in Kathara (single L2 domain + one P4 switch).
- `testbeds/1client_1server`
  - Synthetic OPC UA scenario for controlled certificate-size overhead sweeps.

## Main Documentation
- Testbeds overview and execution guide:
  - [testbeds/README.md](testbeds/README.md)

## Reproducibility Workflow (High Level)
1. Build or pull required Docker images for the selected lab.
2. Run paired measurements (`forward` vs `extraction`) with the per-testbed runner.
3. Run the corresponding analyzer to generate:
   - `per_run.csv`
   - `summary.csv`
   - `report.md`
4. Store outputs under `tests/TESTBEDS` (default for the all-in-one orchestrator).

## Prerequisites
- Docker
- Kathara
- Python 3
- `capinfos` (`wireshark-common`)
- Optional (formal verification): `tamarin-prover`, `maude`

## Security and Data Notes
- This repository contains demo/lab material, including sample certificates/keys and test credentials in some subdirectories.
- Do not reuse these assets in production environments.
- Before publishing derivatives, verify your branch does not contain sensitive runtime artifacts.

## How To Cite
If you use this repository, please cite our paper!

### Paper (preprint)
```bibtex
@article{rinieri2025pkiota,
  title   = {Pk-IOTA: Blockchain empowered Programmable Data Plane to secure OPC UA communications in Industry 4.0},
  author  = {Rinieri, Lorenzo and Gori, Giacomo and Melis, Andrea and Girau, Roberto and Prandini, Marco and Callegati, Franco},
  journal = {arXiv preprint arXiv:2511.10248},
  year    = {2025},
  url     = {https://arxiv.org/abs/2511.10248}
}
```