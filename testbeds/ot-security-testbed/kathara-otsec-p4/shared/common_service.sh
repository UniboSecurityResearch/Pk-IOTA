#!/bin/sh
set -eu

ensure_iproute() {
    if ! command -v ip >/dev/null 2>&1; then
        echo "[bootstrap] missing 'ip' command. Run ./build_kathara_images.sh first." >&2
        exit 127
    fi
}

setup_iface() {
    iface="$1"
    cidr="$2"

    ip addr flush dev "$iface" || true
    ip addr add "$cidr" dev "$iface"
    ip link set "$iface" up
}

add_static_neigh() {
    iface="$1"
    peer_ip="$2"
    peer_mac="$3"
    ip neigh replace "$peer_ip" lladdr "$peer_mac" nud permanent dev "$iface" || true
}

add_host_alias() {
    ip_addr="$1"
    shift
    for host in "$@"; do
        if ! grep -Eq "^[[:space:]]*${ip_addr}[[:space:]].*\\b${host}\\b" /etc/hosts; then
            echo "${ip_addr} ${host}" >> /etc/hosts
        fi
    done
}

populate_otsec_hosts() {
    add_host_alias 10.11.0.11 telegraf
    add_host_alias 10.11.0.12 influxdb
    add_host_alias 10.11.0.13 chronograf
    add_host_alias 10.11.0.14 kapacitor
    add_host_alias 10.11.0.20 industrial-process industrial_process
    add_host_alias 10.11.0.21 plc openplc
    add_host_alias 10.11.0.22 hmi fuxa
    add_host_alias 10.11.0.23 attacker
    add_host_alias 10.11.0.24 shellinabox
}
