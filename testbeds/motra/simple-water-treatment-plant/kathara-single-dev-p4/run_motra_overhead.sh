#!/usr/bin/env bash
set -euo pipefail

usage() {
  cat <<'EOF'
Usage:
  run_motra_overhead.sh [--lab-dir DIR] [--runs N] [--variant V] [--out-dir DIR] [--duration-sec SEC] [--warmup-sec SEC]

Options:
  --lab-dir DIR       Path to MOTRA Kathara lab (default: directory of this script)
  --runs N            Number of paired runs (default: 3)
  --variant V         forward | extraction | both (default: both)
  --out-dir DIR       Output root (default: <lab-dir>/overhead_runs_<timestamp>)
  --duration-sec SEC  Capture duration per variant run (default: 3600)
  --warmup-sec SEC    Wait after lstart before capture starts (default: 30)
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
PORT=4840

while [[ $# -gt 0 ]]; do
  case "$1" in
    --lab-dir) LAB_DIR="${2:-}"; shift 2 ;;
    --runs) RUNS="${2:-}"; shift 2 ;;
    --variant) VARIANT="${2:-}"; shift 2 ;;
    --out-dir) OUT_DIR="${2:-}"; shift 2 ;;
    --duration-sec) DURATION_SEC="${2:-}"; shift 2 ;;
    --warmup-sec) WARMUP_SEC="${2:-}"; shift 2 ;;
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

run_variant_once() {
  local run_index="$1"
  local v="$2"
  local run_dir started finished
  run_dir="$OUT_DIR/run_$(printf '%02d' "$run_index")/$v"
  mkdir -p "$run_dir"

  set_variant "$v"
  clear_shared_captures

  started="$(date -Iseconds)"
  kathara lclean -d "$LAB_DIR" >/dev/null 2>&1 || true
  kathara lstart -d "$LAB_DIR" --noterminals >/dev/null

  if (( WARMUP_SEC > 0 )); then
    echo "  warmup ${WARMUP_SEC}s"
    sleep "$WARMUP_SEC"
  fi

  echo "  starting captures on 4 switches (tcp/$PORT)"
  start_captures
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

  local found=0
  for f in "$run_dir"/s_*_eth*_in.pcap "$run_dir"/s_*_eth*_out.pcap; do
    [[ -f "$f" ]] || continue
    if [[ "$(stat -c %s "$f")" -ge 24 ]]; then
      found=1
      break
    fi
  done
  if [[ "$found" -ne 1 ]]; then
    echo "No valid output pcaps for run=$run_index variant=$v" >&2
    ls -la "$LAB_DIR/shared" >&2 || true
    return 1
  fi
}

echo "Running MOTRA overhead collection"
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
echo "  python3 \"$LAB_DIR/analyze_motra_overhead.py\" --input-dir \"$OUT_DIR\""
