#!/usr/bin/env bash
set -euo pipefail

usage() {
  cat <<'EOF'
Usage:
  run_maynard_overhead.sh [--lab-dir DIR] [--runs N] [--variant V] [--out-dir DIR] [--timeout SEC] [--start-timeout SEC]

Options:
  --lab-dir DIR    Path to Maynard lab directory (default: directory of this script)
  --runs N         Number of paired runs (default: 10)
  --variant V      forward | extraction | both (default: both)
  --out-dir DIR    Output root directory (default: <lab-dir>/overhead_runs_<timestamp>)
  --timeout SEC    Max wait for replay completion per run (default: 1800)
  --start-timeout SEC
                   Max wait for tcpreplay process to appear (default: 120)
  -h, --help       Show this help

Output layout:
  <out-dir>/run_XX/<variant>/s1_ingress.pcap
  <out-dir>/run_XX/<variant>/s1_egress.pcap
  <out-dir>/run_XX/<variant>/switch.log
  <out-dir>/run_XX/<variant>/metadata.env
EOF
}

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
LAB_DIR="$SCRIPT_DIR"
RUNS=10
VARIANT="both"
OUT_DIR=""
REPLAY_TIMEOUT=1800
REPLAY_START_TIMEOUT=120

while [[ $# -gt 0 ]]; do
  case "$1" in
    --lab-dir)
      LAB_DIR="${2:-}"
      shift 2
      ;;
    --runs)
      RUNS="${2:-}"
      shift 2
      ;;
    --variant)
      VARIANT="${2:-}"
      shift 2
      ;;
    --out-dir)
      OUT_DIR="${2:-}"
      shift 2
      ;;
    --timeout)
      REPLAY_TIMEOUT="${2:-}"
      shift 2
      ;;
    --start-timeout)
      REPLAY_START_TIMEOUT="${2:-}"
      shift 2
      ;;
    -h|--help)
      usage
      exit 0
      ;;
    *)
      echo "Unknown argument: $1" >&2
      usage
      exit 1
      ;;
  esac
done

if ! [[ "$RUNS" =~ ^[0-9]+$ ]] || [[ "$RUNS" -lt 1 ]]; then
  echo "Invalid --runs value: $RUNS" >&2
  exit 1
fi

if ! [[ "$REPLAY_TIMEOUT" =~ ^[0-9]+$ ]] || [[ "$REPLAY_TIMEOUT" -lt 1 ]]; then
  echo "Invalid --timeout value: $REPLAY_TIMEOUT" >&2
  exit 1
fi
if ! [[ "$REPLAY_START_TIMEOUT" =~ ^[0-9]+$ ]] || [[ "$REPLAY_START_TIMEOUT" -lt 1 ]]; then
  echo "Invalid --start-timeout value: $REPLAY_START_TIMEOUT" >&2
  exit 1
fi

case "$VARIANT" in
  forward|extraction|both) ;;
  *)
    echo "Invalid --variant value: $VARIANT" >&2
    exit 1
    ;;
esac

S1_DIR="$LAB_DIR/s1"
STARTUP_FILE="$LAB_DIR/s1.startup"
TARGET_P4="$S1_DIR/opcua_extraction.p4"
FORWARD_P4="$S1_DIR/forward.p4"
EXTRACTION_ORIG="$S1_DIR/.opcua_extraction.original.overhead.p4"
STARTUP_ORIG="$LAB_DIR/.s1.startup.original.overhead"
REPLAY_STARTUP_BACKUP_DIR="$LAB_DIR/.replay_startups.original.overhead"

if [[ -z "$OUT_DIR" ]]; then
  OUT_DIR="$LAB_DIR/overhead_runs_$(date +%Y%m%d_%H%M%S)"
fi

for required in "$LAB_DIR/lab.conf" "$S1_DIR/commands.txt" "$STARTUP_FILE" "$TARGET_P4" "$FORWARD_P4"; do
  if [[ ! -f "$required" ]]; then
    echo "Missing required file: $required" >&2
    exit 1
  fi
done

if ! command -v kathara >/dev/null 2>&1; then
  echo "kathara command not found" >&2
  exit 1
fi

mkdir -p "$OUT_DIR"

cleanup() {
  set +e
  kathara lclean -d "$LAB_DIR" >/dev/null 2>&1
  if [[ -f "$EXTRACTION_ORIG" ]]; then
    cp "$EXTRACTION_ORIG" "$TARGET_P4"
    rm -f "$EXTRACTION_ORIG"
  fi
  if [[ -f "$STARTUP_ORIG" ]]; then
    cp "$STARTUP_ORIG" "$STARTUP_FILE"
    rm -f "$STARTUP_ORIG"
  fi
  if [[ -d "$REPLAY_STARTUP_BACKUP_DIR" ]]; then
    for f in "$REPLAY_STARTUP_BACKUP_DIR"/*.startup; do
      [[ -f "$f" ]] || continue
      cp "$f" "$LAB_DIR/$(basename "$f")"
    done
    rm -rf "$REPLAY_STARTUP_BACKUP_DIR"
  fi
}
trap cleanup EXIT

cp "$TARGET_P4" "$EXTRACTION_ORIG"
cp "$STARTUP_FILE" "$STARTUP_ORIG"
mkdir -p "$REPLAY_STARTUP_BACKUP_DIR"

# Force switch logs into /shared/switch.log so we can copy it after each run.
sed \
  -e 's|^simple_switch .*|simple_switch -i 1@eth0 -i 2@eth1 --log-console opcua_extraction.json > /shared/switch.log 2>\&1 \&|' \
  -e 's|^tcpdump -i eth0 -w .*|env PATH=/usr/sbin:/usr/bin:/sbin:/bin:$PATH tcpdump -i eth0 -w /shared/s1_ingress.pcap \&|' \
  -e 's|^tcpdump -i eth1 -w .*|env PATH=/usr/sbin:/usr/bin:/sbin:/bin:$PATH tcpdump -i eth1 -w /shared/s1_egress.pcap \&|' \
  "$STARTUP_ORIG" > "$STARTUP_FILE"

devices=(rtu1 rtu2 rtu3 rtu4 rtu5 historian)

# Delay replay startup to ensure switch/tcpdump are already running.
for device in "${devices[@]}"; do
  src="$LAB_DIR/${device}.startup"
  bak="$REPLAY_STARTUP_BACKUP_DIR/${device}.startup"
  cp "$src" "$bak"
  sed -e 's|^tcpreplay |sleep 20 \&\& tcpreplay |' "$bak" > "$src"
done

wait_for_switch_capture() {
  local start_ts now elapsed count last_log
  start_ts="$(date +%s)"
  last_log=-1
  while true; do
    count="$(kathara exec -d "$LAB_DIR" --wait s1 pgrep -c tcpdump 2>/dev/null | tr -d '[:space:]' || true)"
    if ! [[ "$count" =~ ^[0-9]+$ ]]; then
      # Fallback for containers where pgrep is unavailable.
      pid_list="$(kathara exec -d "$LAB_DIR" --wait s1 pidof tcpdump 2>/dev/null || true)"
      if [[ "$pid_list" =~ [0-9] ]]; then
        count="$(echo "$pid_list" | awk '{print NF}')"
      else
        count=0
      fi
    fi
    if [[ "$count" =~ ^[0-9]+$ ]] && [[ "$count" -ge 2 ]]; then
      echo "  tcpdump active on s1 (count=$count)"
      break
    fi
    now="$(date +%s)"
    elapsed=$((now - start_ts))
    if (( elapsed % 5 == 0 && elapsed != last_log )); then
      echo "  waiting tcpdump on s1... elapsed=${elapsed}s count=${count:-0}"
      last_log=$elapsed
    fi
    if [[ "$elapsed" -gt "$REPLAY_TIMEOUT" ]]; then
      echo "Timeout waiting tcpdump on s1 (${REPLAY_TIMEOUT}s)" >&2
      echo "Debug: PATH/bin probes inside s1" >&2
      kathara exec -d "$LAB_DIR" --wait s1 which tcpdump >&2 || true
      kathara exec -d "$LAB_DIR" --wait s1 ls -l /usr/sbin/tcpdump /usr/bin/tcpdump /bin/tcpdump /sbin/tcpdump >&2 || true
      return 1
    fi
    sleep 1
  done
}

is_process_running() {
  local device="$1"
  local proc="$2"
  if kathara exec -d "$LAB_DIR" --wait "$device" pgrep -x "$proc" >/dev/null 2>&1; then
    return 0
  fi
  if kathara exec -d "$LAB_DIR" --wait "$device" pidof "$proc" >/dev/null 2>&1; then
    return 0
  fi
  return 1
}

wait_for_replays() {
  local start_ts now elapsed running device seen_running last_log started_count
  start_ts="$(date +%s)"
  seen_running=0
  last_log=-1
  while true; do
    running=0
    started_count=0
    for device in "${devices[@]}"; do
      if is_process_running "$device" "tcpreplay"; then
        running=1
        started_count=$((started_count + 1))
      fi
    done
    if [[ "$running" -eq 1 ]]; then
      seen_running=1
    fi
    if [[ "$seen_running" -eq 1 && "$running" -eq 0 ]]; then
      break
    fi
    now="$(date +%s)"
    elapsed=$((now - start_ts))
    if (( elapsed % 5 == 0 && elapsed != last_log )); then
      if [[ "$seen_running" -eq 0 ]]; then
        echo "  waiting tcpreplay start... elapsed=${elapsed}s active_hosts=${started_count}/${#devices[@]}"
      else
        echo "  tcpreplay running... elapsed=${elapsed}s active_hosts=${started_count}/${#devices[@]}"
      fi
      last_log=$elapsed
    fi
    if [[ "$seen_running" -eq 0 && "$elapsed" -gt "$REPLAY_START_TIMEOUT" ]]; then
      echo "tcpreplay did not start within ${REPLAY_START_TIMEOUT}s" >&2
      echo "Debug: per-host process check:" >&2
      for device in "${devices[@]}"; do
        if is_process_running "$device" "tcpreplay"; then
          echo "  $device: running" >&2
        else
          echo "  $device: not running" >&2
        fi
      done
      return 1
    fi
    if [[ "$elapsed" -gt "$REPLAY_TIMEOUT" ]]; then
      echo "Replay timeout exceeded (${REPLAY_TIMEOUT}s)" >&2
      return 1
    fi
    sleep 1
  done
  sleep 2
}

copy_if_exists() {
  local src="$1"
  local dst="$2"
  if [[ -f "$src" ]]; then
    cp "$src" "$dst"
  fi
}

write_metadata() {
  local metadata_file="$1"
  local run_index="$2"
  local v="$3"
  local started="$4"
  local finished="$5"
  local ingress="$6"
  local egress="$7"
  {
    echo "run_index=$run_index"
    echo "variant=$v"
    echo "started_at=$started"
    echo "finished_at=$finished"
    echo "lab_dir=$LAB_DIR"
    echo "ingress_pcap=$(basename "$ingress")"
    echo "egress_pcap=$(basename "$egress")"
    if [[ -f "$ingress" ]]; then
      echo "ingress_packets=$(capinfos -c "$ingress" 2>/dev/null | awk -F: '/Number of packets/{gsub(/ /,"",$2); print $2; exit}')"
    fi
    if [[ -f "$egress" ]]; then
      echo "egress_packets=$(capinfos -c "$egress" 2>/dev/null | awk -F: '/Number of packets/{gsub(/ /,"",$2); print $2; exit}')"
    fi
  } > "$metadata_file"
}

run_variant_once() {
  local run_index="$1"
  local v="$2"
  local run_dir started finished p4_source
  local ingress_src_a ingress_src_b egress_src_a egress_src_b switch_src_a switch_src_b
  local ingress_dst egress_dst switch_dst metadata_dst

  case "$v" in
    forward) p4_source="$FORWARD_P4" ;;
    extraction) p4_source="$EXTRACTION_ORIG" ;;
    *)
      echo "Unknown variant in runner: $v" >&2
      return 1
      ;;
  esac

  run_dir="$OUT_DIR/run_$(printf '%02d' "$run_index")/$v"
  mkdir -p "$run_dir"

  cp "$p4_source" "$TARGET_P4"

  rm -f "$S1_DIR/s1_ingress.pcap" "$S1_DIR/s1_egress.pcap" "$S1_DIR/switch.log"
  rm -f "$LAB_DIR/shared/s1_ingress.pcap" "$LAB_DIR/shared/s1_egress.pcap" "$LAB_DIR/shared/switch.log"

  started="$(date -Iseconds)"
  kathara lclean -d "$LAB_DIR" >/dev/null 2>&1 || true
  kathara lstart -d "$LAB_DIR" --noterminals
  echo "  phase: waiting switch capture startup"
  wait_for_switch_capture
  echo "  phase: waiting replay completion"
  wait_for_replays
  kathara lclean -d "$LAB_DIR" >/dev/null
  finished="$(date -Iseconds)"

  ingress_src_a="$S1_DIR/s1_ingress.pcap"
  ingress_src_b="$LAB_DIR/shared/s1_ingress.pcap"
  egress_src_a="$S1_DIR/s1_egress.pcap"
  egress_src_b="$LAB_DIR/shared/s1_egress.pcap"
  switch_src_a="$LAB_DIR/shared/switch.log"
  switch_src_b="$S1_DIR/switch.log"

  ingress_dst="$run_dir/s1_ingress.pcap"
  egress_dst="$run_dir/s1_egress.pcap"
  switch_dst="$run_dir/switch.log"
  metadata_dst="$run_dir/metadata.env"

  copy_if_exists "$ingress_src_a" "$ingress_dst"
  copy_if_exists "$ingress_src_b" "$ingress_dst"
  copy_if_exists "$egress_src_a" "$egress_dst"
  copy_if_exists "$egress_src_b" "$egress_dst"
  copy_if_exists "$switch_src_a" "$switch_dst"
  copy_if_exists "$switch_src_b" "$switch_dst"

  write_metadata "$metadata_dst" "$run_index" "$v" "$started" "$finished" "$ingress_dst" "$egress_dst"

  if [[ ! -f "$ingress_dst" || ! -f "$egress_dst" ]]; then
    echo "Missing output pcaps for run=$run_index variant=$v" >&2
    echo "Debug: files currently in $LAB_DIR/shared" >&2
    ls -la "$LAB_DIR/shared" >&2 || true
    echo "Debug: files currently in $S1_DIR" >&2
    ls -la "$S1_DIR" >&2 || true
    return 1
  fi

  # 24 bytes is the minimum global pcap header size. Smaller means empty/corrupt capture.
  if [[ "$(stat -c %s "$ingress_dst")" -lt 24 || "$(stat -c %s "$egress_dst")" -lt 24 ]]; then
    echo "Output pcaps are empty/corrupt for run=$run_index variant=$v" >&2
    echo "Debug: ingress_size=$(stat -c %s "$ingress_dst") egress_size=$(stat -c %s "$egress_dst")" >&2
    echo "Debug: Docker/Kathara permissions and tcpdump runtime should be checked." >&2
    return 1
  fi
}

echo "Running Maynard overhead collection"
echo "lab_dir=$LAB_DIR"
echo "out_dir=$OUT_DIR"
echo "runs=$RUNS variant=$VARIANT timeout=${REPLAY_TIMEOUT}s start_timeout=${REPLAY_START_TIMEOUT}s"

for ((i=1; i<=RUNS; i++)); do
  if [[ "$VARIANT" == "both" ]]; then
    echo "[run $i/$RUNS] variant=forward"
    run_variant_once "$i" "forward"
    echo "[run $i/$RUNS] variant=extraction"
    run_variant_once "$i" "extraction"
  else
    echo "[run $i/$RUNS] variant=$VARIANT"
    run_variant_once "$i" "$VARIANT"
  fi
done

echo "Collection completed."
echo "Output directory: $OUT_DIR"
echo "Next step:"
echo "  python3 \"$LAB_DIR/analyze_maynard_overhead.py\" --input-dir \"$OUT_DIR\""
