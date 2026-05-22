#!/usr/bin/env bash
set -euo pipefail

BASE_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(cd "$BASE_DIR/.." && pwd)"
TMP_DIR="$(mktemp -d)"
trap 'rm -rf "$TMP_DIR"' EXIT

build_wrapper() {
  local base="$1"
  local tag="$2"
  cat > "$TMP_DIR/Dockerfile" <<EOD
FROM ${base}
RUN set -eux; \
    if ! apt-get update; then \
      sed -ri 's|http://deb.debian.org/debian|http://archive.debian.org/debian|g; s|http://security.debian.org/debian-security|http://archive.debian.org/debian-security|g' /etc/apt/sources.list || true; \
      sed -ri '/stretch-updates/d' /etc/apt/sources.list || true; \
      printf 'Acquire::Check-Valid-Until "false";\n' > /etc/apt/apt.conf.d/99archive-no-valid-until; \
      apt-get -o Acquire::Check-Valid-Until=false update; \
    fi; \
    apt-get install -y --no-install-recommends iproute2; \
    if [ -f /entrypoint.sh ]; then chmod +x /entrypoint.sh; fi; \
    rm -rf /var/lib/apt/lists/*
EOD
  docker build -t "$tag" "$TMP_DIR"
}

echo "Building OT testbed base images..."
docker build -t ot-industrial-process:latest -f "$ROOT_DIR/industrial-process/industrial-process.Dockerfile" "$ROOT_DIR/industrial-process"
docker build -t ot-openplc:latest -f "$ROOT_DIR/PLC/OpenPLC.Dockerfile" "$ROOT_DIR/PLC"
docker build -t ot-fuxa:latest -f Dockerfile "https://github.com/vembacher/FUXA.git#d85ef526f234dee7194b56a7de7902050202a950"
docker build -t ot-attacker:latest -f "$ROOT_DIR/attacker/attacker.Dockerfile" "$ROOT_DIR/attacker"
docker build -t ot-shellinabox:latest -f "$ROOT_DIR/attacker/shellinabox.Dockerfile" "$ROOT_DIR/attacker"

echo "Building wrapper images (*:kathara-net) with iproute2..."
build_wrapper telegraf:1.21.4 telegraf:kathara-net
build_wrapper influxdb:1.8.10 influxdb:kathara-net
build_wrapper chronograf:1.9.4 chronograf:kathara-net
build_wrapper kapacitor:1.6.4 kapacitor:kathara-net
build_wrapper ot-industrial-process:latest ot-industrial-process:kathara-net
build_wrapper ot-openplc:latest ot-openplc:kathara-net
build_wrapper ot-fuxa:latest ot-fuxa:kathara-net
build_wrapper ot-attacker:latest ot-attacker:kathara-net
build_wrapper ot-shellinabox:latest ot-shellinabox:kathara-net

cp "$BASE_DIR/common_service.sh" "$BASE_DIR/shared/common_service.sh"
chmod 644 "$BASE_DIR/shared/common_service.sh"

echo "Done. Images ready."
