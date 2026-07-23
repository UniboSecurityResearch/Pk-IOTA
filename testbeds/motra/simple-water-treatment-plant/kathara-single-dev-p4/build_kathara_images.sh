#!/usr/bin/env bash
set -euo pipefail

LAB_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
MOTRA_DIR="$(cd "$LAB_DIR/../.." && pwd)"
TMP_DIR="$(mktemp -d)"
trap 'rm -rf "$TMP_DIR"' EXIT

if ! command -v openssl >/dev/null 2>&1; then
    echo "Missing command: openssl" >&2
    exit 1
fi

PKI_DIR="$TMP_DIR/pki"
mkdir -p "$PKI_DIR"
openssl req -x509 -newkey rsa:2048 -nodes -days 3650 \
    -subj "/CN=motra-opcua-server/O=MOTRA" \
    -keyout "$PKI_DIR/server-key.pem" \
    -out "$PKI_DIR/server-cert.pem" >/dev/null 2>&1
openssl req -x509 -newkey rsa:2048 -nodes -days 3650 \
    -subj "/CN=motra-opcua-client/O=MOTRA" \
    -keyout "$PKI_DIR/client-key.pem" \
    -out "$PKI_DIR/client-cert.pem" >/dev/null 2>&1

mkdir -p "$LAB_DIR/shared/pki"
cp "$PKI_DIR"/* "$LAB_DIR/shared/pki/"
# Both thumbprints are needed by the extraction P4 table: the client->server
# OPN carries the server-cert thumbprint, the server->client OPN response
# carries the client-cert thumbprint.
{
    openssl x509 -in "$PKI_DIR/server-cert.pem" -noout -fingerprint -sha1
    openssl x509 -in "$PKI_DIR/client-cert.pem" -noout -fingerprint -sha1
} | awk -F= '{print $2}' \
    | tr -d ':' \
    | tr 'A-Z' 'a-z' \
    | awk '{print "0x"$1}' > "$LAB_DIR/shared/motra-server-thumbprints.txt"

build_one() {
    local base="$1"
    local tag="$2"
    local app_src="${3:-}"
    local server_src="${4:-}"
    local ctx="$TMP_DIR/${tag//[:\/]/_}"

    mkdir -p "$ctx"
    cp "$PKI_DIR"/* "$ctx/"
    if [[ -n "$app_src" ]]; then
        cp -a "$app_src" "$ctx/app"
    fi
    if [[ -n "$server_src" ]]; then
        cp "$server_src" "$ctx/server.py"
    fi

    {
        echo "FROM ${base}"
        echo "RUN apt-get update && apt-get install -y --no-install-recommends iproute2 openssl && rm -rf /var/lib/apt/lists/*"
        echo "RUN mkdir -p /pki"
        echo "COPY server-cert.pem /pki/server-cert.pem"
        echo "COPY server-key.pem /pki/server-key.pem"
        echo "COPY client-cert.pem /pki/client-cert.pem"
        echo "COPY client-key.pem /pki/client-key.pem"
        echo "RUN chmod 0644 /pki/*-cert.pem && chmod 0600 /pki/*-key.pem"
        if [[ -n "$app_src" ]]; then
            echo "COPY app/ /app/"
        fi
        if [[ -n "$server_src" ]]; then
            echo "COPY server.py /usr/src/app/server.py"
        fi
    } > "$ctx/Dockerfile"

    docker build -t "${tag}" "$ctx"
}

OPCUA_IMAGES="$MOTRA_DIR/motra-images/opcua"
SERVER_SRC="$OPCUA_IMAGES/server/python-opcua-asyncio/latest/src/server.py"

build_one \
    "loriringhio97/motra-dashboard-kathara-net:v1" \
    "dashboard:kathara-net" \
    "$OPCUA_IMAGES/dashboard/python-opcua-asyncio/latest/app"

build_one \
    "loriringhio97/motra-plc-server-kathara-net:v1" \
    "plc-server:kathara-net" \
    "" \
    "$SERVER_SRC"

build_one \
    "loriringhio97/motra-historian-kathara-net:v1" \
    "historian:kathara-net" \
    "$OPCUA_IMAGES/historian/python-opcua-asyncio/latest/app"

build_one \
    "loriringhio97/motra-plc-logic-kathara-net:v1" \
    "plc-logic:kathara-net" \
    "$OPCUA_IMAGES/plc-logic/python-opcua-asyncio/latest/app"

build_one \
    "loriringhio97/motra-levelsensor-server-kathara-net:v1" \
    "levelsensor-server:kathara-net" \
    "" \
    "$SERVER_SRC"

build_one \
    "loriringhio97/motra-water-tank-simulation-kathara-net:v1" \
    "water-tank-simulation:kathara-net" \
    "$OPCUA_IMAGES/water-tank-simulation/python-opcua-asyncio/latest/app"

build_one \
    "loriringhio97/motra-valve-server-kathara-net:v1" \
    "valve-server:kathara-net" \
    "" \
    "$SERVER_SRC"

cp "${LAB_DIR}/common_service.sh" "${LAB_DIR}/shared/common_service.sh"
chmod 644 "${LAB_DIR}/shared/common_service.sh"

echo "Built wrapper images (*:kathara-net) and refreshed shared/common_service.sh"
