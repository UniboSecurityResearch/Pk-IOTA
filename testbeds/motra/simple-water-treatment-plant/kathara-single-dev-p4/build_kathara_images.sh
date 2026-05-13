#!/usr/bin/env bash
set -euo pipefail

LAB_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TMP_DIR="$(mktemp -d)"
trap 'rm -rf "$TMP_DIR"' EXIT

build_one() {
    local base="$1"
    local tag="$2"
    cat >"$TMP_DIR/Dockerfile" <<EOF
FROM ${base}
RUN apt-get update && apt-get install -y --no-install-recommends iproute2 && rm -rf /var/lib/apt/lists/*
EOF
    docker build -t "${tag}" "$TMP_DIR"
}

build_one "dashboard:latest" "dashboard:kathara-net"
build_one "plc-server:latest" "plc-server:kathara-net"
build_one "historian:latest" "historian:kathara-net"
build_one "plc-logic:latest" "plc-logic:kathara-net"
build_one "levelsensor-server:latest" "levelsensor-server:kathara-net"
build_one "water-tank-simulation:latest" "water-tank-simulation:kathara-net"
build_one "valve-server:latest" "valve-server:kathara-net"

cp "${LAB_DIR}/common_service.sh" "${LAB_DIR}/shared/common_service.sh"
chmod 644 "${LAB_DIR}/shared/common_service.sh"

echo "Built wrapper images (*:kathara-net) and refreshed shared/common_service.sh"
