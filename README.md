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

his repository contains the code and the dataset for the paper "Pk-IOTA: Blockchain empowered Programmable Data Plane to secure OPC UA communications in Industry 4.0"

## Repository Structure
- **IOTA_src:** contains all the source code to run the certificate transactions on the IOTA ledger; it also contains the source code of smart contracts and the frontend that interacts with it. All the dependencies and guides to run the software and the tests are inside the directory.
- **Testbed:** Provides a simulation environment for in-network certificate validation of OPC UA certificates.
- **Test:** Contains test scripts and data to reproduce our results.

## Prerequisites
To get started with Pk-IOTA, ensure the following prerequisites are installed on your system:

1. **IOTA SDK:**
   - Install the IOTA SDK by following the [official installation guide](https://docs.iota.org/).

2. **Kathara Framework:**
   - Install Kathara by following the [official documentation](https://www.kathara.org/).

## Installation
Clone the repository:
   ```bash
   git clone https://github.com/UniboSecurityResearch/Pk-IOTA.git
   cd Pk-IOTA
   ```

## Usage

1. Navigate to the `testbed` folder:
   ```bash
   cd testbed
   ```

2. Run Kathara to start the simulation:
   ```bash
   kathara lstart
   ```

3. In the `h1` terminal of Kathara, execute the following command:
   ```bash
   python3 ua_client_with_encryption.py
   ```

### Cite us
If you find this work interesting and use it in your academic research, please cite our paper!

[![DOI](https://zenodo.org/badge/749721589.svg)](https://doi.org/10.5281/zenodo.14751962)
