#!/bin/sh
set -eu

log_ts() {
    date -Iseconds 2>/dev/null || date
}

ensure_iproute() {
    if ! command -v ip >/dev/null 2>&1; then
        echo "$(log_ts) [bootstrap] missing 'ip' command. Build wrapper images first (run ./build_kathara_images.sh)." >&2
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
