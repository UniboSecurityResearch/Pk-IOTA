#!/usr/bin/env bash
set -euo pipefail

for pidf in /shared/tcpdump_eth0_in.pid /shared/tcpdump_eth0_out.pid /shared/tcpdump_eth1_in.pid /shared/tcpdump_eth1_out.pid; do
  if [[ -f "$pidf" ]]; then
    pid="$(cat "$pidf" || true)"
    if [[ -n "${pid}" ]]; then
      kill "$pid" >/dev/null 2>&1 || true
    fi
  fi
done

pkill -TERM tcpdump >/dev/null 2>&1 || true
sleep 1
pkill -KILL tcpdump >/dev/null 2>&1 || true

echo "capture_stopped"
