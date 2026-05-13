#!/usr/bin/env bash
set -euo pipefail

PORT="${1:-4840}"

rm -f /shared/s1_eth0_in.pcap /shared/s1_eth0_out.pcap /shared/s1_eth1_in.pcap /shared/s1_eth1_out.pcap
rm -f /shared/tcpdump_eth0_in.pid /shared/tcpdump_eth0_out.pid /shared/tcpdump_eth1_in.pid /shared/tcpdump_eth1_out.pid

for iface in eth0 eth1; do
  for direction in in out; do
    out="/shared/s1_${iface}_${direction}.pcap"
    log="/shared/tcpdump_${iface}_${direction}.log"
    nohup tcpdump -U -Q "$direction" -i "$iface" -w "$out" tcp port "$PORT" >"$log" 2>&1 &
    pid="$!"
    echo "$pid" > "/shared/tcpdump_${iface}_${direction}.pid"
  done
done

echo "capture_started port=${PORT}"
