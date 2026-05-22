#!/usr/bin/env bash
set -euo pipefail

usage() {
  cat <<'EOF'
Usage:
  run_otsec_overhead.sh [--lab-dir DIR] [--runs N] [--variant V] [--out-dir DIR] [--duration-sec SEC] [--warmup-sec SEC] [--start-timeout SEC] [--stimulate]

Options:
  --lab-dir DIR       Path to OT Security Kathara lab (default: directory of this script)
  --runs N            Number of paired runs (default: 3)
  --variant V         forward | extraction | both (default: both)
  --out-dir DIR       Output root (default: <lab-dir>/overhead_runs_<timestamp>)
  --duration-sec SEC  Capture duration per variant run (default: 3600)
  --warmup-sec SEC    Wait after lstart before capture starts (default: 30)
  --start-timeout SEC Maximum time allowed for kathara lstart (default: 180)
  --stimulate         Actively trigger OPC UA polling from telegraf before capture
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
VARIANT="both"
OUT_DIR=""
DURATION_SEC=3600
WARMUP_SEC=30
START_TIMEOUT_SEC=180
STIMULATE=0
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
    --stimulate) STIMULATE=1; shift ;;
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
case "$VARIANT" in
  forward|extraction|both) ;;
  *) echo "Invalid --variant value: $VARIANT" >&2; exit 1 ;;
esac

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
if ! command -v docker >/dev/null 2>&1; then
  echo "docker command not found" >&2
  exit 1
fi
if ! command -v capinfos >/dev/null 2>&1; then
  echo "capinfos command not found (install wireshark-common)" >&2
  exit 1
fi

declare -a REQUIRED_IMAGES=()
mapfile -t REQUIRED_IMAGES < <(awk -F'"' '/\[image\]=/ {print $2}' "$LAB_DIR/lab.conf" | sed '/^$/d' | sort -u)
declare -a MISSING_IMAGES=()
for image in "${REQUIRED_IMAGES[@]}"; do
  if ! docker image inspect "$image" >/dev/null 2>&1; then
    MISSING_IMAGES+=("$image")
  fi
done
if (( ${#MISSING_IMAGES[@]} > 0 )); then
  echo "Missing Docker images required by this lab:" >&2
  for image in "${MISSING_IMAGES[@]}"; do
    echo "  - $image" >&2
  done
  echo "Build/pull them first. For local OTSEC images: ./build_kathara_images.sh" >&2
  exit 1
fi

mkdir -p "$OUT_DIR"

declare -a SWITCHES=("s1")
declare -A SWITCH_PORTS=(
  [s1]=9
)
declare -a CAPTURE_JOBS=()
CAPTURE_MODE_USED="unknown"

cleanup() {
  set +e
  for sw in "${SWITCHES[@]}"; do
    kathara exec -d "$LAB_DIR" "$sw" -- pkill tcpdump >/dev/null 2>&1 || true
  done
  for pid in "${CAPTURE_JOBS[@]:-}"; do
    wait "$pid" >/dev/null 2>&1 || true
  done
  kathara lclean -d "$LAB_DIR" >/dev/null 2>&1 || true
}
trap cleanup EXIT

clear_shared_captures() {
  rm -f "$LAB_DIR/shared"/s_*_eth*_in.pcap "$LAB_DIR/shared"/s_*_eth*_out.pcap
  rm -f "$LAB_DIR/shared"/s_*_eth*_in.tcpdump.log "$LAB_DIR/shared"/s_*_eth*_out.tcpdump.log
}

expected_capture_processes() {
  local total=0
  local sw
  for sw in "${SWITCHES[@]}"; do
    total=$((total + SWITCH_PORTS[$sw] * 2))
  done
  echo "$total"
}

running_tcpdump_processes() {
  local total=0
  local sw
  for sw in "${SWITCHES[@]}"; do
    local c
    c="$(kathara exec -d "$LAB_DIR" "$sw" -- sh -lc "pgrep -xc tcpdump || true" 2>/dev/null | tail -n1 | tr -dc '0-9')"
    c="${c:-0}"
    total=$((total + c))
  done
  echo "$total"
}

shared_has_pcap_header_for_dir() {
  local dir="$1"
  local f
  for sw in "${SWITCHES[@]}"; do
    for f in "$LAB_DIR/shared"/${sw}_eth*_"${dir}".pcap; do
      [[ -f "$f" ]] || continue
      if [[ "$(stat -c %s "$f" 2>/dev/null || echo 0)" -ge 24 ]]; then
        return 0
      fi
    done
  done
  return 1
}

start_captures_with_mode() {
  local mode="$1"
  local expected
  expected="$(expected_capture_processes)"
  CAPTURE_JOBS=()
  for sw in "${SWITCHES[@]}"; do
    local ports="${SWITCH_PORTS[$sw]}"
    for ((p=0; p<ports; p++)); do
      for dir in in out; do
        local out="/shared/${sw}_eth${p}_${dir}.pcap"
        local log="/shared/${sw}_eth${p}_${dir}.tcpdump.log"
        local cmd
        if [[ "$mode" == "qflag" ]]; then
          cmd="exec tcpdump -s 0 -U -Q '$dir' -i 'eth${p}' -w '$out' 'tcp port $PORT' >'$log' 2>&1"
        else
          local qual="inbound"
          [[ "$dir" == "out" ]] && qual="outbound"
          cmd="exec tcpdump -s 0 -U -i 'eth${p}' -w '$out' '$qual and tcp port $PORT' >'$log' 2>&1"
        fi
        kathara exec -d "$LAB_DIR" "$sw" -- sh -lc "$cmd" &
        CAPTURE_JOBS+=("$!")
      done
    done
  done

  local waited=0
  while (( waited < 20 )); do
    sleep 2
    waited=$((waited + 2))
    local running
    running="$(running_tcpdump_processes)"
    if [[ "$running" =~ ^[0-9]+$ ]] && (( running >= expected )) \
      && shared_has_pcap_header_for_dir "in" \
      && shared_has_pcap_header_for_dir "out"; then
      CAPTURE_MODE_USED="$mode"
      return 0
    fi
  done

  stop_captures
  return 1
}

start_captures() {
  if start_captures_with_mode "qflag"; then
    echo "  capture mode: tcpdump -Q in/out"
    return 0
  fi
  echo "  capture mode -Q failed, retrying with BPF inbound/outbound filter"
  if start_captures_with_mode "bpf_direction"; then
    echo "  capture mode: BPF inbound/outbound"
    return 0
  fi
  return 1
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
      for f in "$OUT_DIR/run_$(printf '%02d' "$run_index")/$v"/${sw}_eth*.tcpdump.log; do
        [[ -f "$f" ]] || continue
        local lines
        lines="$(wc -l < "$f" 2>/dev/null || echo 0)"
        echo "$(basename "$f" .tcpdump.log)_tcpdump_log_lines=$lines"
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

stimulate_traffic() {
  echo "  phase: stimulate OPC UA traffic (telegraf --once)"
  # Run one forced collection round; ignore failure but log it.
  kathara exec -d "$LAB_DIR" telegraf -- sh -lc \
    "telegraf --config /etc/telegraf/telegraf.conf --once >/shared/telegraf_once.log 2>&1" >/dev/null 2>&1 || true
}

set_variant() {
  local v="$1"
  "$LAB_DIR/set_p4_variant.sh" "$v"
}

dump_failed_container_context() {
  local startup_log="$1"
  local cid=""
  cid="$(grep -Eo '[0-9a-f]{64}' "$startup_log" | tail -n1 || true)"
  if [[ -z "$cid" ]]; then
    return 0
  fi

  echo "Detected failed container id: $cid" >&2
  docker ps -a --no-trunc --format '{{.ID}} {{.Names}} {{.Status}}' | grep "$cid" >&2 || true
  echo "---- docker inspect (state) ----" >&2
  docker inspect --format 'Name={{.Name}} Status={{.State.Status}} ExitCode={{.State.ExitCode}} Error={{.State.Error}} OOMKilled={{.State.OOMKilled}}' "$cid" >&2 || true
  echo "---- docker logs (tail 120) ----" >&2
  docker logs --tail 120 "$cid" >&2 || true
}

run_variant_once() {
  local run_index="$1"
  local v="$2"
  local run_dir started finished startup_log
  run_dir="$OUT_DIR/run_$(printf '%02d' "$run_index")/$v"
  mkdir -p "$run_dir"
  startup_log="$run_dir/kathara_lstart.log"

  echo "  phase: set variant ($v)"
  if ! set_variant "$v"; then
    echo "Failed to set P4 variant: $v" >&2
    return 1
  fi
  clear_shared_captures

  started="$(date -Iseconds)"
  echo "  phase: lab cleanup/start"
  kathara lclean -d "$LAB_DIR" >/dev/null 2>&1 || true
  local lstart_rc
  if command -v timeout >/dev/null 2>&1; then
    set +e
    timeout "${START_TIMEOUT_SEC}s" kathara lstart -d "$LAB_DIR" --noterminals >"$startup_log" 2>&1
    lstart_rc=$?
    set -e
  else
    set +e
    kathara lstart -d "$LAB_DIR" --noterminals >"$startup_log" 2>&1
    lstart_rc=$?
    set -e
  fi
  if [[ "$lstart_rc" -ne 0 ]]; then
    echo "kathara lstart failed for run=$run_index variant=$v" >&2
    if [[ "$lstart_rc" -eq 124 ]]; then
      echo "kathara lstart timed out after ${START_TIMEOUT_SEC}s" >&2
    fi
    echo "Inspect startup log: $startup_log" >&2
    tail -n 80 "$startup_log" >&2 || true
    dump_failed_container_context "$startup_log" || true
    return 1
  fi
  echo "  phase: lab started"

  if (( WARMUP_SEC > 0 )); then
    echo "  warmup ${WARMUP_SEC}s"
    sleep "$WARMUP_SEC"
  fi
  echo "  starting captures on switch s1 (tcp/$PORT)"
  if ! start_captures; then
    echo "Failed to start captures on s1 (both capture modes failed)." >&2
    echo "Inspect shared tcpdump logs under: $LAB_DIR/shared/s1_eth*_*.tcpdump.log" >&2
    kathara lclean -d "$LAB_DIR" >/dev/null 2>&1 || true
    return 1
  fi
  if (( STIMULATE == 1 )); then
    stimulate_traffic
    sleep 2
  fi
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
    for f in "$LAB_DIR/shared"/${sw}_eth*_in.tcpdump.log; do
      [[ -f "$f" ]] || continue
      cp "$f" "$run_dir/$(basename "$f")"
    done
    for f in "$LAB_DIR/shared"/${sw}_eth*_out.tcpdump.log; do
      [[ -f "$f" ]] || continue
      cp "$f" "$run_dir/$(basename "$f")"
    done
  done

  write_metadata "$run_dir/metadata.env" "$run_index" "$v" "$started" "$finished"

  local found_in=0
  local found_out=0
  for f in "$run_dir"/s_*_eth*_in.pcap; do
    [[ -f "$f" ]] || continue
    if [[ "$(stat -c %s "$f")" -ge 24 ]]; then
      found_in=1
      break
    fi
  done
  for f in "$run_dir"/s_*_eth*_out.pcap; do
    [[ -f "$f" ]] || continue
    if [[ "$(stat -c %s "$f")" -ge 24 ]]; then
      found_out=1
      break
    fi
  done
  if [[ "$found_in" -ne 1 || "$found_out" -ne 1 ]]; then
    echo "Missing valid directional pcaps for run=$run_index variant=$v (in=$found_in out=$found_out)" >&2
    echo "Likely causes: tcpdump -Q direction unsupported in container, bad interface index, or no tcpdump startup." >&2
    echo "Capture mode used: $CAPTURE_MODE_USED" >&2
    echo "Inspect logs in: $run_dir/*tcpdump.log" >&2
    ls -la "$LAB_DIR/shared" >&2 || true
    return 1
  fi
}

echo "Running OT Security overhead collection"
echo "lab_dir=$LAB_DIR"
echo "out_dir=$OUT_DIR"
echo "runs=$RUNS variant=$VARIANT duration=${DURATION_SEC}s warmup=${WARMUP_SEC}s"

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
echo "  python3 \"$LAB_DIR/analyze_otsec_overhead.py\" --input-dir \"$OUT_DIR\""
