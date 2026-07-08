#!/usr/bin/env bash
set -euo pipefail

usage() {
  cat <<'EOF'
Usage:
  run_motra_overhead.sh [--lab-dir DIR] [--runs N] [--variant V] [--out-dir DIR] [--duration-sec SEC] [--warmup-sec SEC] [--start-timeout SEC]

Options:
  --lab-dir DIR       Path to MOTRA Kathara lab (default: directory of this script)
  --runs N            Number of paired runs (default: 3)
  --variant V         ip_forward | opcua_forward | extraction | forward | both | all (default: all)
  --out-dir DIR       Output root (default: <lab-dir>/overhead_runs_<timestamp>)
  --duration-sec SEC  Capture duration per variant run (default: 3600)
  --warmup-sec SEC    Wait after lstart before capture starts (default: 30)
  --start-timeout SEC Maximum time allowed for kathara lstart (default: 180)
  -h, --help          Show this help

Output layout:
  <out-dir>/run_XX/<variant>/*.pcap
  <out-dir>/run_XX/<variant>/metadata.env
  <out-dir>/run_XX/<variant>/s_*.log
EOF
}

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
LAB_DIR="$SCRIPT_DIR"
RUNS=3
VARIANT="all"
OUT_DIR=""
DURATION_SEC=3600
WARMUP_SEC=30
START_TIMEOUT_SEC=180
PORT=4840

while [[ $# -gt 0 ]]; do
  case "$1" in
    --lab-dir) LAB_DIR="${2:-}"; shift 2 ;;
    --runs) RUNS="${2:-}"; shift 2 ;;
    --variant) VARIANT="${2:-}"; shift 2 ;;
    --out-dir) OUT_DIR="${2:-}"; shift 2 ;;
    --duration-sec) DURATION_SEC="${2:-}"; shift 2 ;;
    --warmup-sec) WARMUP_SEC="${2:-}"; shift 2 ;;
    --start-timeout) START_TIMEOUT_SEC="${2:-}"; shift 2 ;;
    -h|--help) usage; exit 0 ;;
    *) echo "Unknown argument: $1" >&2; usage; exit 1 ;;
  esac
done

if ! [[ "$RUNS" =~ ^[0-9]+$ ]] || [[ "$RUNS" -lt 1 ]]; then
  echo "Invalid --runs value: $RUNS" >&2
  exit 1
fi
if ! [[ "$DURATION_SEC" =~ ^[0-9]+$ ]] || [[ "$DURATION_SEC" -lt 1 ]]; then
  echo "Invalid --duration-sec value: $DURATION_SEC" >&2
  exit 1
fi
if ! [[ "$WARMUP_SEC" =~ ^[0-9]+$ ]] || [[ "$WARMUP_SEC" -lt 0 ]]; then
  echo "Invalid --warmup-sec value: $WARMUP_SEC" >&2
  exit 1
fi
if ! [[ "$START_TIMEOUT_SEC" =~ ^[0-9]+$ ]] || [[ "$START_TIMEOUT_SEC" -lt 10 ]]; then
  echo "Invalid --start-timeout value: $START_TIMEOUT_SEC (min 10)" >&2
  exit 1
fi
expand_variants() {
  case "$1" in
    ip_forward) echo "ip_forward" ;;
    opcua_forward|forward) echo "opcua_forward" ;;
    extraction) echo "extraction" ;;
    both) echo "opcua_forward extraction" ;;
    all) echo "ip_forward opcua_forward extraction" ;;
    *) echo "Invalid --variant value: $1" >&2; return 1 ;;
  esac
}

variant_expansion="$(expand_variants "$VARIANT")" || exit 1
read -r -a VARIANTS_TO_RUN <<< "$variant_expansion"

if [[ -z "$OUT_DIR" ]]; then
  OUT_DIR="$LAB_DIR/overhead_runs_$(date +%Y%m%d_%H%M%S)"
fi

for required in "$LAB_DIR/lab.conf" "$LAB_DIR/set_p4_variant.sh"; do
  if [[ ! -f "$required" ]]; then
    echo "Missing required file: $required" >&2
    exit 1
  fi
done
if ! command -v kathara >/dev/null 2>&1; then
  echo "kathara command not found" >&2
  exit 1
fi
if ! command -v capinfos >/dev/null 2>&1; then
  echo "capinfos command not found (install wireshark-common)" >&2
  exit 1
fi

mkdir -p "$OUT_DIR"

declare -a SWITCHES=("s_it" "s_plc" "s_ot" "s_lsensor")
declare -A SWITCH_PORTS=(
  [s_it]=2
  [s_plc]=3
  [s_ot]=3
  [s_lsensor]=2
)
declare -a CAPTURE_JOBS=()
COMMAND_BACKUP_DIR="$LAB_DIR/.commands.original.overhead"

backup_switch_commands() {
  mkdir -p "$COMMAND_BACKUP_DIR"
  for sw in "${SWITCHES[@]}"; do
    if [[ ! -f "$COMMAND_BACKUP_DIR/${sw}.commands.txt" ]]; then
      cp "$LAB_DIR/$sw/commands.txt" "$COMMAND_BACKUP_DIR/${sw}.commands.txt"
    fi
  done
}

restore_switch_commands() {
  if [[ ! -d "$COMMAND_BACKUP_DIR" ]]; then
    return 0
  fi
  for sw in "${SWITCHES[@]}"; do
    if [[ -f "$COMMAND_BACKUP_DIR/${sw}.commands.txt" ]]; then
      cp "$COMMAND_BACKUP_DIR/${sw}.commands.txt" "$LAB_DIR/$sw/commands.txt"
    fi
  done
  rm -rf "$COMMAND_BACKUP_DIR"
}

cleanup() {
  set +e
  for sw in "${SWITCHES[@]}"; do
    kathara exec -d "$LAB_DIR" "$sw" -- pkill tcpdump >/dev/null 2>&1 || true
  done
  for pid in "${CAPTURE_JOBS[@]:-}"; do
    wait "$pid" >/dev/null 2>&1 || true
  done
  restore_switch_commands
  kathara lclean -d "$LAB_DIR" >/dev/null 2>&1 || true
}
trap cleanup EXIT

clear_shared_captures() {
  rm -f "$LAB_DIR/shared"/s_*_eth*_in.pcap "$LAB_DIR/shared"/s_*_eth*_out.pcap
  rm -f "$LAB_DIR/shared"/*_thumbprints.commands
}

start_captures() {
  CAPTURE_JOBS=()
  for sw in "${SWITCHES[@]}"; do
    local ports="${SWITCH_PORTS[$sw]}"
    for ((p=0; p<ports; p++)); do
      for dir in in out; do
        local out="/shared/${sw}_eth${p}_${dir}.pcap"
        kathara exec -d "$LAB_DIR" "$sw" -- tcpdump -U -Q "$dir" -i "eth${p}" -w "$out" tcp port "$PORT" >/dev/null 2>&1 &
        CAPTURE_JOBS+=("$!")
      done
    done
  done
  sleep 3
}

stop_captures() {
  for sw in "${SWITCHES[@]}"; do
    kathara exec -d "$LAB_DIR" "$sw" -- pkill tcpdump >/dev/null 2>&1 || true
  done
  sleep 2
  for pid in "${CAPTURE_JOBS[@]}"; do
    wait "$pid" >/dev/null 2>&1 || true
  done
  CAPTURE_JOBS=()
}

copy_if_exists() {
  local src="$1"
  local dst="$2"
  [[ -f "$src" ]] && cp "$src" "$dst"
}

packet_count() {
  local pcap="$1"
  capinfos -c "$pcap" 2>/dev/null | awk -F: '/Number of packets/ {gsub(/^[ \t]+/, "", $2); print $2; exit}'
}

cert_thumbprint_from_container() {
  local dev="$1"
  local cert_path="$2"
  kathara exec -d "$LAB_DIR" "$dev" -- openssl x509 -in "$cert_path" -noout -fingerprint -sha1 \
    | awk -F= '{print $2}' | tr -d ':' | tr 'A-Z' 'a-z' | awk '{print "0x"$1}'
}

program_extraction_thumbprints() {
  local v="$1"
  local run_dir="$2"
  local sw dev thumb count cmd_file
  local -a thumbs=()
  local -A seen=()

  if [[ "$v" != "extraction" ]]; then
    return 0
  fi

  for dev in plc_server levelsensor_server valve_server; do
    thumb="$(cert_thumbprint_from_container "$dev" /pki/server-cert.pem | tail -n1)"
    if [[ "$thumb" =~ ^0x[0-9a-f]{40}$ && -z "${seen[$thumb]:-}" ]]; then
      thumbs+=("$thumb")
      seen[$thumb]=1
    fi
  done

  # The server -> client OPN *response* carries the thumbprint of the CLIENT
  # certificate: without it in the table (default_action=drop) the handshake
  # can never complete in extraction mode. All images embed the same
  # /pki/client-cert.pem, so any container can provide it.
  thumb="$(cert_thumbprint_from_container plc_server /pki/client-cert.pem | tail -n1)"
  if [[ "$thumb" =~ ^0x[0-9a-f]{40}$ && -z "${seen[$thumb]:-}" ]]; then
    thumbs+=("$thumb")
    seen[$thumb]=1
  fi

  if [[ "${#thumbs[@]}" -eq 0 ]]; then
    echo "No MOTRA server certificate thumbprints available; did you rebuild wrapper images?" >&2
    return 1
  fi

  for sw in "${SWITCHES[@]}"; do
    cmd_file="$LAB_DIR/shared/${sw}_thumbprints.commands"
    {
      echo "table_clear thumbprint_table"
      for thumb in "${thumbs[@]}"; do
        echo "table_add thumbprint_table NoAction $thumb =>"
      done
      echo "table_dump thumbprint_table"
    } > "$cmd_file"
    cp "$cmd_file" "$run_dir/${sw}_thumbprints.commands"
    kathara exec -d "$LAB_DIR" "$sw" -- sh -lc "simple_switch_CLI < /shared/${sw}_thumbprints.commands" >"$run_dir/${sw}_thumbprints.log" 2>&1
  done
}

write_variant_commands() {
  local v="$1"
  local sw thumb
  local thumb_file="$LAB_DIR/shared/motra-server-thumbprints.txt"

  backup_switch_commands
  for sw in "${SWITCHES[@]}"; do
    grep -v -e 'thumbprint_table' -e '^EOF[[:space:]]*$' "$COMMAND_BACKUP_DIR/${sw}.commands.txt" > "$LAB_DIR/$sw/commands.txt"
    if [[ "$v" == "extraction" && -s "$thumb_file" ]]; then
      while IFS= read -r thumb; do
        [[ "$thumb" =~ ^0x[0-9a-f]{40}$ ]] || continue
        echo "table_add thumbprint_table NoAction $thumb =>" >> "$LAB_DIR/$sw/commands.txt"
      done < "$thumb_file"
    fi
  done
}

write_metadata() {
  local metadata_file="$1"
  local run_index="$2"
  local v="$3"
  local started="$4"
  local finished="$5"
  {
    echo "run_index=$run_index"
    echo "variant=$v"
    echo "started_at=$started"
    echo "finished_at=$finished"
    echo "lab_dir=$LAB_DIR"
    echo "duration_sec=$DURATION_SEC"
    echo "warmup_sec=$WARMUP_SEC"
    echo "start_timeout_sec=$START_TIMEOUT_SEC"
    echo "port=$PORT"
    for sw in "${SWITCHES[@]}"; do
      for f in "$OUT_DIR/run_$(printf '%02d' "$run_index")/$v"/${sw}_eth*_in.pcap; do
        [[ -f "$f" ]] || continue
        echo "$(basename "$f" .pcap)_packets=$(packet_count "$f")"
      done
      for f in "$OUT_DIR/run_$(printf '%02d' "$run_index")/$v"/${sw}_eth*_out.pcap; do
        [[ -f "$f" ]] || continue
        echo "$(basename "$f" .pcap)_packets=$(packet_count "$f")"
      done
    done
  } > "$metadata_file"
}

sleep_with_progress() {
  local seconds="$1"
  local elapsed=0
  while (( elapsed < seconds )); do
    sleep 5
    elapsed=$((elapsed + 5))
    if (( elapsed % 60 == 0 || elapsed == seconds )); then
      echo "  capture running... ${elapsed}/${seconds}s"
    fi
  done
}

set_variant() {
  local v="$1"
  "$LAB_DIR/set_p4_variant.sh" "$v" >/dev/null
}

OPCUA_SERVERS=(plc_server levelsensor_server valve_server)
declare -A OPCUA_SERVER_IPS=(
  [plc_server]="10.10.20.11"
  [levelsensor_server]="10.10.30.12"
  [valve_server]="10.10.30.13"
)

wait_for_opcua_servers() {
  local dev ip deadline
  deadline=$((SECONDS + START_TIMEOUT_SEC))
  for dev in "${OPCUA_SERVERS[@]}"; do
    ip="${OPCUA_SERVER_IPS[$dev]}"
    while true; do
      # NOTE: never pass a bare `-c` token to kathara exec: the Nuitka-packaged
      # kathara binary intercepts it ("program tried to call itself with '-c'").
      # Wrap in `sh -lc` so kathara only sees -lc plus one string argument.
      if kathara exec -d "$LAB_DIR" plc_logic -- sh -lc \
        "python3 -c \"import socket; socket.create_connection(('$ip', $PORT), timeout=2).close()\"" >/dev/null 2>&1; then
        break
      fi
      if (( SECONDS >= deadline )); then
        echo "Server $dev ($ip:$PORT) not listening; check /shared/${dev}.log in the lab" >&2
        return 1
      fi
      sleep 3
    done
  done
}

restart_opcua_servers() {
  local dev
  for dev in "${OPCUA_SERVERS[@]}"; do
    kathara exec -d "$LAB_DIR" "$dev" -- sh -lc \
      "pkill -f 'python server.py' >/dev/null 2>&1 || true; sleep 1; nohup /start_app.sh >> /shared/${dev}.log 2>&1 &" \
      >/dev/null 2>&1 || true
  done
  # Give servers time to come back and clients time to reconnect (2s retry loop).
  wait_for_opcua_servers || echo "WARNING: servers slow to return after restart" >&2
  sleep 5
}

run_variant_once() {
  local run_index="$1"
  local v="$2"
  local run_dir started finished startup_log lstart_rc
  run_dir="$OUT_DIR/run_$(printf '%02d' "$run_index")/$v"
  mkdir -p "$run_dir"
  startup_log="$run_dir/kathara_lstart.log"

  set_variant "$v" || return 1
  write_variant_commands "$v" || return 1
  for sw in "${SWITCHES[@]}"; do
    copy_if_exists "$LAB_DIR/$sw/commands.txt" "$run_dir/${sw}_commands.txt"
  done
  clear_shared_captures

  started="$(date -Iseconds)"
  kathara lclean -d "$LAB_DIR" >/dev/null 2>&1 || true
  set +e
  timeout "${START_TIMEOUT_SEC}s" kathara lstart -d "$LAB_DIR" --noterminals >"$startup_log" 2>&1
  lstart_rc=$?
  set -e
  if [[ "$lstart_rc" -ne 0 ]]; then
    echo "kathara lstart failed for run=$run_index variant=$v" >&2
    if [[ "$lstart_rc" -eq 124 ]]; then
      echo "kathara lstart timed out after ${START_TIMEOUT_SEC}s" >&2
    fi
    echo "Inspect startup log: $startup_log" >&2
    tail -n 80 "$startup_log" >&2 || true
    return 1
  fi
  echo "  waiting for OPC UA servers to listen (tcp/$PORT)"
  if ! wait_for_opcua_servers; then
    echo "OPC UA servers did not come up for run=$run_index variant=$v" >&2
    return 1
  fi

  echo "  programming extraction thumbprints if needed"
  program_extraction_thumbprints "$v" "$run_dir" || return 1

  echo "  starting captures on 4 switches (tcp/$PORT)"
  start_captures
  if (( WARMUP_SEC > 0 )); then
    echo "  warmup ${WARMUP_SEC}s during capture"
    sleep "$WARMUP_SEC"
  fi

  # Certificates cross the wire only during OpenSecureChannel. The clients
  # connected at boot, before the capture started: restart the servers so every
  # client reconnects (their retry loops) and fresh OPN handshakes with
  # certificates happen INSIDE the capture window.
  echo "  restarting OPC UA servers to force OPN handshakes inside the capture"
  restart_opcua_servers

  sleep_with_progress "$DURATION_SEC"
  echo "  stopping captures"
  stop_captures
  kathara lclean -d "$LAB_DIR" >/dev/null
  finished="$(date -Iseconds)"

  for sw in "${SWITCHES[@]}"; do
    copy_if_exists "$LAB_DIR/shared/${sw}.log" "$run_dir/${sw}.log"
    for f in "$LAB_DIR/shared"/${sw}_eth*_in.pcap; do
      [[ -f "$f" ]] || continue
      cp "$f" "$run_dir/$(basename "$f")"
    done
    for f in "$LAB_DIR/shared"/${sw}_eth*_out.pcap; do
      [[ -f "$f" ]] || continue
      cp "$f" "$run_dir/$(basename "$f")"
    done
  done

  write_metadata "$run_dir/metadata.env" "$run_index" "$v" "$started" "$finished"

  # tcpdump writes a 24-byte header immediately, so file size alone passes on
  # empty captures: require actual packets.
  local found=0 pkts
  for f in "$run_dir"/s_*_eth*_in.pcap "$run_dir"/s_*_eth*_out.pcap; do
    [[ -f "$f" ]] || continue
    pkts="$(packet_count "$f")"
    if [[ -n "$pkts" && "$pkts" -gt 0 ]]; then
      found=1
      break
    fi
  done
  if [[ "$found" -ne 1 ]]; then
    echo "No OPC UA packets captured for run=$run_index variant=$v" >&2
    echo "Check the app logs copied from /shared (e.g. plc_server.log, plc_logic.log)" >&2
    ls -la "$LAB_DIR/shared" >&2 || true
    return 1
  fi
}

echo "Running MOTRA overhead collection"
echo "lab_dir=$LAB_DIR"
echo "out_dir=$OUT_DIR"
echo "runs=$RUNS variant=$VARIANT expanded=${VARIANTS_TO_RUN[*]} duration=${DURATION_SEC}s warmup=${WARMUP_SEC}s start_timeout=${START_TIMEOUT_SEC}s"

FAILED_RUNS=()
for ((i=1; i<=RUNS; i++)); do
  for variant in "${VARIANTS_TO_RUN[@]}"; do
    echo "[run $i/$RUNS] variant=$variant"
    if ! run_variant_once "$i" "$variant"; then
      FAILED_RUNS+=("run=$i variant=$variant")
      echo "FAILED: run=$i variant=$variant (continuing with next run)" >&2
    fi
  done
done

echo "Collection completed."
echo "Output directory: $OUT_DIR"
if [[ "${#FAILED_RUNS[@]}" -gt 0 ]]; then
  printf '%s\n' "${FAILED_RUNS[@]}" > "$OUT_DIR/failed_runs.txt"
  echo "WARNING: ${#FAILED_RUNS[@]} run(s) failed (see $OUT_DIR/failed_runs.txt):" >&2
  printf '  %s\n' "${FAILED_RUNS[@]}" >&2
  exit 1
fi
echo "Next step:"
echo "  python3 \"$LAB_DIR/analyze_motra_overhead.py\" --input-dir \"$OUT_DIR\" --require-extraction-opn-cert"
