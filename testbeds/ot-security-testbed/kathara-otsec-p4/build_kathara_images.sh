#!/usr/bin/env bash
set -euo pipefail

BASE_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(cd "$BASE_DIR/.." && pwd)"
TMP_DIR="$(mktemp -d)"
trap 'rm -rf "$TMP_DIR"' EXIT
CERT_DIR="$ROOT_DIR/certificates"

require_cert() {
  local path="$1"
  if [[ ! -f "$path" ]]; then
    echo "Missing required OTSEC certificate/key: $path" >&2
    echo "Generate certificates first with: (cd \"$ROOT_DIR/certificates\" && ./create-certs.sh)" >&2
    exit 1
  fi
}

write_iproute_layer() {
  cat <<'EOD'
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
}

build_wrapper() {
  local base="$1"
  local tag="$2"
  cat > "$TMP_DIR/Dockerfile" <<EOD
FROM ${base}
EOD
  write_iproute_layer >> "$TMP_DIR/Dockerfile"
  docker build -t "$tag" "$TMP_DIR"
}

build_telegraf_wrapper() {
  local ctx="$TMP_DIR/telegraf-wrapper"
  mkdir -p "$ctx"

  require_cert "$CERT_DIR/applications/telegraf.crt"
  require_cert "$CERT_DIR/applications/telegraf.key"
  require_cert "$CERT_DIR/applications/plc.crt.der"

  cp "$CERT_DIR/applications/telegraf.crt" "$ctx/telegraf.crt"
  cp "$CERT_DIR/applications/telegraf.key" "$ctx/telegraf.key"
  cp "$CERT_DIR/applications/plc.crt.der" "$ctx/plc.crt.der"

  cat > "$ctx/Dockerfile" <<'EOD'
FROM telegraf:1.21.4
RUN mkdir -p /opt/otsec/certs
COPY telegraf.crt /opt/otsec/certs/telegraf.crt
COPY telegraf.key /opt/otsec/certs/telegraf.key
COPY plc.crt.der /opt/otsec/certs/plc.crt.der
RUN chmod 0644 /opt/otsec/certs/telegraf.crt /opt/otsec/certs/plc.crt.der && chmod 0640 /opt/otsec/certs/telegraf.key
EOD
  write_iproute_layer >> "$ctx/Dockerfile"
  docker build -t telegraf:kathara-net "$ctx"
}

build_industrial_process_wrapper() {
  local ctx="$TMP_DIR/industrial-process-wrapper"
  mkdir -p "$ctx"

  require_cert "$CERT_DIR/applications/industrial-process.crt.der"
  require_cert "$CERT_DIR/applications/industrial-process.key"
  require_cert "$CERT_DIR/applications/telegraf.crt.der"

  cp "$CERT_DIR/applications/industrial-process.crt.der" "$ctx/industrial-process.der"
  cp "$CERT_DIR/applications/industrial-process.key" "$ctx/industrial-process.pem"
  cp "$CERT_DIR/applications/telegraf.crt.der" "$ctx/telegraf.der"

  cat > "$ctx/Dockerfile" <<'EOD'
FROM ot-industrial-process:latest
COPY industrial-process.der /usr/src/simulator/industrial-process.der
COPY industrial-process.pem /usr/src/simulator/industrial-process.pem
COPY telegraf.der /usr/src/simulator/telegraf.der
EOD
  write_iproute_layer >> "$ctx/Dockerfile"
  docker build -t ot-industrial-process:kathara-net "$ctx"
}

build_openplc_wrapper() {
  local ctx="$TMP_DIR/openplc-wrapper"
  mkdir -p "$ctx"

  require_cert "$CERT_DIR/applications/plc.crt.der"
  require_cert "$CERT_DIR/applications/plc.key.der"
  require_cert "$CERT_DIR/ca/ca.crt.der"
  require_cert "$CERT_DIR/ca/ca.crl"

  cp "$CERT_DIR/applications/plc.crt.der" "$ctx/plc.crt.der"
  cp "$CERT_DIR/applications/plc.key.der" "$ctx/plc.key.der"
  cp "$CERT_DIR/ca/ca.crt.der" "$ctx/ca.crt.der"
  cp "$CERT_DIR/ca/ca.crl" "$ctx/ca.crl"

  cat > "$ctx/Dockerfile" <<'EOD'
FROM ot-openplc:latest
RUN mkdir -p \
      /workdir/OpenPLC_v3/etc/PKI/own/certs \
      /workdir/OpenPLC_v3/etc/PKI/own/private \
      /workdir/OpenPLC_v3/etc/PKI/trusted/certs \
      /workdir/OpenPLC_v3/etc/PKI/trusted/crl
COPY plc.crt.der /workdir/OpenPLC_v3/etc/PKI/own/certs/plc.crt.der
COPY plc.key.der /workdir/OpenPLC_v3/etc/PKI/own/private/plc.key.der
COPY ca.crt.der /workdir/OpenPLC_v3/etc/PKI/trusted/certs/ca.crt.der
COPY ca.crl /workdir/OpenPLC_v3/etc/PKI/trusted/crl/ca.crl
EOD
  write_iproute_layer >> "$ctx/Dockerfile"
  docker build -t ot-openplc:kathara-net "$ctx"
}

echo "Building OT testbed base images..."
docker build -t ot-industrial-process:latest -f "$ROOT_DIR/industrial-process/industrial-process.Dockerfile" "$ROOT_DIR/industrial-process"
docker build -t ot-openplc:latest -f "$ROOT_DIR/PLC/OpenPLC.Dockerfile" "$ROOT_DIR/PLC"
docker build -t ot-fuxa:latest -f Dockerfile "https://github.com/vembacher/FUXA.git#d85ef526f234dee7194b56a7de7902050202a950"
docker build -t ot-attacker:latest -f "$ROOT_DIR/attacker/attacker.Dockerfile" "$ROOT_DIR/attacker"
docker build -t ot-shellinabox:latest -f "$ROOT_DIR/attacker/shellinabox.Dockerfile" "$ROOT_DIR/attacker"

echo "Building wrapper images (*:kathara-net) with iproute2..."
build_telegraf_wrapper
build_wrapper influxdb:1.8.10 influxdb:kathara-net
build_wrapper chronograf:1.9.4 chronograf:kathara-net
build_wrapper kapacitor:1.6.4 kapacitor:kathara-net
build_industrial_process_wrapper
build_openplc_wrapper
build_wrapper ot-fuxa:latest ot-fuxa:kathara-net
build_wrapper ot-attacker:latest ot-attacker:kathara-net
build_wrapper ot-shellinabox:latest ot-shellinabox:kathara-net

cp "$BASE_DIR/common_service.sh" "$BASE_DIR/shared/common_service.sh"
chmod 644 "$BASE_DIR/shared/common_service.sh"

echo "Done. Images ready."
