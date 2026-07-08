#!/usr/bin/env bash
set -euo pipefail

usage() {
  cat <<'EOF'
Usage:
  run_maynard_overhead.sh [--lab-dir DIR] [--runs N] [--variant V] [--out-dir DIR] [--timeout SEC] [--start-timeout SEC] [--duration-sec SEC]

Options:
  --lab-dir DIR    Path to Maynard lab directory (default: directory of this script)
  --runs N         Number of paired runs (default: 10)
  --variant V      ip_forward | opcua_forward | extraction | forward | both | all (default: all)
  --out-dir DIR    Output root directory (default: <lab-dir>/overhead_runs_<timestamp>)
  --timeout SEC    Max wait for replay completion per run (default: 1800)
  --start-timeout SEC
                   Max wait for tcpreplay process to appear (default: 120)
  --duration-sec SEC
                   Capture/replay window after tcpreplay starts; 0 waits for replay completion (default: 0)
  -h, --help       Show this help

Output layout:
  <out-dir>/run_XX/<variant>/s1_ingress.pcap
  <out-dir>/run_XX/<variant>/s1_egress.pcap
  <out-dir>/run_XX/<variant>/switch.log
  <out-dir>/run_XX/<variant>/metadata.env
EOF
}

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TESTBEDS_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
LAB_DIR="$SCRIPT_DIR"
RUNS=10
VARIANT="all"
OUT_DIR=""
REPLAY_TIMEOUT=1800
REPLAY_START_TIMEOUT=120
CAPTURE_DURATION_SEC=0
TCPREPLAY_SPEED_ARGS=""

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
    --duration-sec)
      CAPTURE_DURATION_SEC="${2:-}"
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
if ! [[ "$CAPTURE_DURATION_SEC" =~ ^[0-9]+$ ]]; then
  echo "Invalid --duration-sec value: $CAPTURE_DURATION_SEC" >&2
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

if [[ "$CAPTURE_DURATION_SEC" -gt 0 ]]; then
  TCPREPLAY_SPEED_ARGS="--mbps 1"
fi

S1_DIR="$LAB_DIR/s1"
STARTUP_FILE="$LAB_DIR/s1.startup"
TARGET_P4="$S1_DIR/opcua_extraction.p4"
IP_FORWARD_P4="$S1_DIR/ip_forward.p4"
FORWARD_P4="$S1_DIR/forward.p4"
EXTRACTION_ORIG="$S1_DIR/.opcua_extraction.original.overhead.p4"
STARTUP_ORIG="$LAB_DIR/.s1.startup.original.overhead"
COMMANDS_FILE="$S1_DIR/commands.txt"
COMMANDS_ORIG="$S1_DIR/.commands.original.overhead.txt"
REPLAY_STARTUP_BACKUP_DIR="$LAB_DIR/.replay_startups.original.overhead"

if [[ -z "$OUT_DIR" ]]; then
  OUT_DIR="$LAB_DIR/overhead_runs_$(date +%Y%m%d_%H%M%S)"
fi

for required in "$LAB_DIR/lab.conf" "$COMMANDS_FILE" "$STARTUP_FILE" "$TARGET_P4" "$IP_FORWARD_P4" "$FORWARD_P4"; do
  if [[ ! -f "$required" ]]; then
    echo "Missing required file: $required" >&2
    exit 1
  fi
done

if ! command -v kathara >/dev/null 2>&1; then
  echo "kathara command not found" >&2
  exit 1
fi

restore_previous_run_state() {
  if [[ -f "$EXTRACTION_ORIG" ]]; then
    cp "$EXTRACTION_ORIG" "$TARGET_P4"
    rm -f "$EXTRACTION_ORIG"
  fi
  if [[ -f "$STARTUP_ORIG" ]]; then
    cp "$STARTUP_ORIG" "$STARTUP_FILE"
    rm -f "$STARTUP_ORIG"
  fi
  if [[ -f "$COMMANDS_ORIG" ]]; then
    cp "$COMMANDS_ORIG" "$COMMANDS_FILE"
    rm -f "$COMMANDS_ORIG"
  fi
  if [[ -d "$REPLAY_STARTUP_BACKUP_DIR" ]]; then
    for f in "$REPLAY_STARTUP_BACKUP_DIR"/*.startup; do
      [[ -f "$f" ]] || continue
      cp "$f" "$LAB_DIR/$(basename "$f")"
    done
    rm -rf "$REPLAY_STARTUP_BACKUP_DIR"
  fi
}

restore_previous_run_state
mkdir -p "$OUT_DIR"

cleanup() {
  set +e
  kathara lclean -d "$LAB_DIR" >/dev/null 2>&1
  restore_previous_run_state
}
trap cleanup EXIT

cp "$TARGET_P4" "$EXTRACTION_ORIG"
cp "$STARTUP_FILE" "$STARTUP_ORIG"
cp "$COMMANDS_FILE" "$COMMANDS_ORIG"
mkdir -p "$REPLAY_STARTUP_BACKUP_DIR"

# Force switch logs into /shared/switch.log so we can copy it after each run.
sed \
  -e 's|^simple_switch .*|simple_switch -i 1@eth0 -i 2@eth1 --log-console opcua_extraction.json > /shared/switch.log 2>\&1 \&|' \
  -e 's|^tcpdump -i eth0 -w .*|env PATH=/usr/sbin:/usr/bin:/sbin:/bin:$PATH tcpdump -s 0 -U -Q in -i eth0 -w /shared/s1_eth0_in.pcap tcp port 8666 >/shared/tcpdump_eth0_in.log 2>\&1 \&\nenv PATH=/usr/sbin:/usr/bin:/sbin:/bin:$PATH tcpdump -s 0 -U -Q out -i eth0 -w /shared/s1_eth0_out.pcap tcp port 8666 >/shared/tcpdump_eth0_out.log 2>\&1 \&|' \
  -e 's|^tcpdump -i eth1 -w .*|env PATH=/usr/sbin:/usr/bin:/sbin:/bin:$PATH tcpdump -s 0 -U -Q in -i eth1 -w /shared/s1_eth1_in.pcap tcp port 8666 >/shared/tcpdump_eth1_in.log 2>\&1 \&\nenv PATH=/usr/sbin:/usr/bin:/sbin:/bin:$PATH tcpdump -s 0 -U -Q out -i eth1 -w /shared/s1_eth1_out.pcap tcp port 8666 >/shared/tcpdump_eth1_out.log 2>\&1 \&|' \
  "$STARTUP_ORIG" > "$STARTUP_FILE"

devices=(rtu1 rtu2 rtu3 rtu4 rtu5 historian)

# Replays start only when the runner touches /shared/replay_go, i.e. AFTER the
# switch is compiled+running and all tcpdumps are active. A fixed boot stagger
# cannot guarantee that: p4c compile time differs per variant and per host, so
# early replay packets would be silently lost from the captures.
for device in "${devices[@]}"; do
  src="$LAB_DIR/${device}.startup"
  bak="$REPLAY_STARTUP_BACKUP_DIR/${device}.startup"
  cp "$src" "$bak"
  awk -v dev="$device" -v speed_args="$TCPREPLAY_SPEED_ARGS" -v go_timeout="$REPLAY_START_TIMEOUT" '
    /^ip addr add .* dev eth0/ {
      print "ip link set dev eth0 mtu 9000"
      print "ip addr flush dev eth0 >/dev/null 2>&1 || true"
      next
    }
    /^tcpreplay / {
      cmd = $0
      sub(/^tcpreplay /, "", cmd)
      sub(/[[:space:]]*&[[:space:]]*$/, "", cmd)
      print "sh -c '\''i=0; while [ ! -f /shared/replay_go ] && [ $i -lt " go_timeout " ]; do sleep 1; i=$((i+1)); done; touch /shared/" dev "_tcpreplay_started; tcpreplay " speed_args " " cmd " > /shared/" dev "_tcpreplay.log 2>&1; echo $? > /shared/" dev "_tcpreplay.rc; touch /shared/" dev "_tcpreplay_done'\'' &"
      next
    }
    { print }
  ' "$bak" > "$src"
done

wait_for_switch_capture() {
  local start_ts now elapsed count last_log pid_list
  start_ts="$(date +%s)"
  last_log=-1
  while true; do
    count="$(kathara exec -d "$LAB_DIR" --wait s1 pgrep -cx tcpdump 2>/dev/null | tr -d '[:space:]' || true)"
    if ! [[ "$count" =~ ^[0-9]+$ ]]; then
      # Fallback for containers where pgrep is unavailable.
      pid_list="$(kathara exec -d "$LAB_DIR" --wait s1 pidof tcpdump 2>/dev/null || true)"
      if [[ "$pid_list" =~ [0-9] ]]; then
        count="$(echo "$pid_list" | awk '{print NF}')"
      else
        count=0
      fi
    fi
    if [[ "$count" =~ ^[0-9]+$ ]] && [[ "$count" -ge 4 ]]; then
      echo "  tcpdump active on s1 (count=$count)"
      break
    fi
    now="$(date +%s)"
    elapsed=$((now - start_ts))
    if (( elapsed % 5 == 0 && elapsed != last_log )); then
      echo "  waiting tcpdump on s1... elapsed=${elapsed}s count=${count:-0}"
      last_log=$elapsed
    fi
    if [[ "$elapsed" -gt "$REPLAY_START_TIMEOUT" ]]; then
      echo "Timeout waiting tcpdump on s1 (${REPLAY_START_TIMEOUT}s)" >&2
      echo "Likely cause: p4c failed to compile the active P4 program; check the switch log:" >&2
      tail -n 20 "$LAB_DIR/shared/switch.log" >&2 2>/dev/null || true
      echo "Debug: PATH/bin probes inside s1" >&2
      kathara exec -d "$LAB_DIR" --wait s1 which tcpdump >&2 || true
      kathara exec -d "$LAB_DIR" --wait s1 ls -l /usr/sbin/tcpdump /usr/bin/tcpdump /bin/tcpdump /sbin/tcpdump >&2 || true
      return 1
    fi
    sleep 1
  done
}

stop_switch_capture() {
  kathara exec -d "$LAB_DIR" --wait s1 -- sh -lc "pkill -TERM tcpdump 2>/dev/null || true; sleep 2; pkill -KILL tcpdump 2>/dev/null || true" >/dev/null 2>&1 || true
}

stop_replays() {
  local device
  for device in "${devices[@]}"; do
    kathara exec -d "$LAB_DIR" --wait "$device" -- sh -lc "pkill -TERM tcpreplay 2>/dev/null || true" >/dev/null 2>&1 || true
  done
  sleep 2
  for device in "${devices[@]}"; do
    kathara exec -d "$LAB_DIR" --wait "$device" -- sh -lc "pkill -KILL tcpreplay 2>/dev/null || true" >/dev/null 2>&1 || true
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
  local start_ts now elapsed running device seen_running last_log started_count done_count replay_started_ts capture_elapsed
  start_ts="$(date +%s)"
  seen_running=0
  replay_started_ts=0
  last_log=-1
  while true; do
    running=0
    started_count=0
    done_count=0
    for device in "${devices[@]}"; do
      if [[ -f "$LAB_DIR/shared/${device}_tcpreplay_started" ]]; then
        started_count=$((started_count + 1))
      fi
      if [[ -f "$LAB_DIR/shared/${device}_tcpreplay_done" ]]; then
        done_count=$((done_count + 1))
      fi
      if is_process_running "$device" "tcpreplay"; then
        running=1
      fi
    done
    now="$(date +%s)"
    elapsed=$((now - start_ts))
    if [[ "$started_count" -gt 0 && "$seen_running" -eq 0 ]]; then
      seen_running=1
      replay_started_ts="$now"
    elif [[ "$running" -eq 1 || "$started_count" -gt 0 ]]; then
      seen_running=1
    fi
    if [[ "$done_count" -eq "${#devices[@]}" ]]; then
      break
    fi
    if [[ "$seen_running" -eq 1 && "$CAPTURE_DURATION_SEC" -gt 0 ]]; then
      capture_elapsed=$((now - replay_started_ts))
      if [[ "$capture_elapsed" -ge "$CAPTURE_DURATION_SEC" ]]; then
        echo "  capture duration reached (${CAPTURE_DURATION_SEC}s); stopping tcpreplay"
        stop_replays
        break
      fi
    else
      capture_elapsed=0
    fi
    if (( elapsed % 5 == 0 && elapsed != last_log )); then
      if [[ "$seen_running" -eq 0 ]]; then
        echo "  waiting tcpreplay start... elapsed=${elapsed}s started_hosts=${started_count}/${#devices[@]}"
      elif [[ "$CAPTURE_DURATION_SEC" -gt 0 ]]; then
        echo "  tcpreplay running... elapsed=${elapsed}s capture=${capture_elapsed}/${CAPTURE_DURATION_SEC}s done_hosts=${done_count}/${#devices[@]}"
      else
        echo "  tcpreplay running... elapsed=${elapsed}s done_hosts=${done_count}/${#devices[@]}"
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
          echo "  $device: not running started=$(test -f "$LAB_DIR/shared/${device}_tcpreplay_started" && echo yes || echo no) done=$(test -f "$LAB_DIR/shared/${device}_tcpreplay_done" && echo yes || echo no)" >&2
        fi
      done
      return 1
    fi
    if [[ "$elapsed" -gt "$REPLAY_TIMEOUT" ]]; then
      echo "Replay timeout exceeded (${REPLAY_TIMEOUT}s)" >&2
      echo "Debug: per-host tcpreplay process snapshot:" >&2
      for device in "${devices[@]}"; do
        echo "  [$device]" >&2
        kathara exec -d "$LAB_DIR" --wait "$device" -- sh -lc "pgrep -af tcpreplay || true" >&2 || true
      done
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
    echo "capture_duration_sec=$CAPTURE_DURATION_SEC"
    echo "replay_timeout_sec=$REPLAY_TIMEOUT"
    echo "replay_start_timeout_sec=$REPLAY_START_TIMEOUT"
    echo "tcpreplay_speed_args=${TCPREPLAY_SPEED_ARGS:-realtime}"
    echo "tcpreplay_stagger_sec=historian:20,rtu1:25,rtu2:30,rtu3:35,rtu4:40,rtu5:45"
    echo "ingress_pcap=$(basename "$ingress")"
    echo "egress_pcap=$(basename "$egress")"
    if [[ -f "$ingress" ]]; then
      echo "ingress_packets=$(capinfos -c "$ingress" 2>/dev/null | awk -F: '/Number of packets/{gsub(/ /,"",$2); print $2; exit}')"
    fi
    if [[ -f "$egress" ]]; then
      echo "egress_packets=$(capinfos -c "$egress" 2>/dev/null | awk -F: '/Number of packets/{gsub(/ /,"",$2); print $2; exit}')"
    fi
    for p in "$(dirname "$metadata_file")"/s1_eth*.pcap; do
      [[ -f "$p" ]] || continue
      echo "$(basename "$p" .pcap)_packets=$(capinfos -c "$p" 2>/dev/null | awk -F: '/Number of packets/{gsub(/ /,"",$2); print $2; exit}')"
    done
  } > "$metadata_file"
}

source_pcap_paths() {
  local pcap
  for pcap in "$LAB_DIR"/rtu*/rtu*.pcap "$LAB_DIR"/historian/historian.pcap; do
    [[ -f "$pcap" ]] || continue
    printf '%s\n' "$pcap"
  done
}

write_variant_commands() {
  local v="$1"
  local helper="$TESTBEDS_DIR/extract_opcua_thumbprints.py"
  local pcap_paths=()
  local thumb

  grep -v -e 'thumbprint_table' -e '^EOF[[:space:]]*$' "$COMMANDS_ORIG" > "$COMMANDS_FILE"

  if [[ "$v" != "extraction" ]]; then
    return 0
  fi

  while IFS= read -r pcap; do
    pcap_paths+=("$pcap")
  done < <(source_pcap_paths)

  if [[ "${#pcap_paths[@]}" -eq 0 ]]; then
    echo "No Maynard source pcap found for thumbprint extraction" >&2
    return 1
  fi

  # Run the extractor to a temp file so its exit status is NOT masked by a
  # process substitution: with an empty thumbprint_table and default_action=drop
  # the extraction variant silently drops every OPN and the comparison is void.
  local thumbs_file
  thumbs_file="$(mktemp)"
  if ! python3 "$helper" --port 8666 "${pcap_paths[@]}" > "$thumbs_file"; then
    rm -f "$thumbs_file"
    echo "Thumbprint extraction failed (python3 $helper)" >&2
    return 1
  fi

  local added=0
  while IFS= read -r thumb; do
    [[ -n "$thumb" ]] || continue
    echo "table_add thumbprint_table NoAction $thumb =>" >> "$COMMANDS_FILE"
    added=$((added + 1))
  done < "$thumbs_file"
  rm -f "$thumbs_file"

  if [[ "$added" -eq 0 ]]; then
    echo "Thumbprint extraction produced 0 entries: extraction variant would drop all OPN traffic" >&2
    return 1
  fi
  echo "  programmed $added thumbprint(s) into commands.txt"
}

run_variant_once() {
  local run_index="$1"
  local v="$2"
  local run_dir started finished p4_source
  local ingress_src_a ingress_src_b egress_src_a egress_src_b switch_src_a switch_src_b
  local ingress_dst egress_dst switch_dst metadata_dst

  case "$v" in
    ip_forward) p4_source="$IP_FORWARD_P4" ;;
    opcua_forward) p4_source="$FORWARD_P4" ;;
    extraction) p4_source="$EXTRACTION_ORIG" ;;
    *)
      echo "Unknown variant in runner: $v" >&2
      return 1
      ;;
  esac

  run_dir="$OUT_DIR/run_$(printf '%02d' "$run_index")/$v"
  mkdir -p "$run_dir"

  cp "$p4_source" "$TARGET_P4"
  write_variant_commands "$v" || return 1
  copy_if_exists "$COMMANDS_FILE" "$run_dir/commands.txt"

  rm -f "$S1_DIR/s1_ingress.pcap" "$S1_DIR/s1_egress.pcap" "$S1_DIR/switch.log"
  rm -f "$LAB_DIR/shared/s1_ingress.pcap" "$LAB_DIR/shared/s1_egress.pcap" "$LAB_DIR/shared/s1_eth"*.pcap "$LAB_DIR/shared/switch.log"
  rm -f "$LAB_DIR/shared"/*_tcpreplay_started "$LAB_DIR/shared"/*_tcpreplay_done "$LAB_DIR/shared"/*_tcpreplay.rc "$LAB_DIR/shared"/*_tcpreplay.log
  rm -f "$LAB_DIR/shared/replay_go"

  started="$(date -Iseconds)"
  kathara lclean -d "$LAB_DIR" >/dev/null 2>&1 || true
  kathara lstart -d "$LAB_DIR" --noterminals || return 1
  echo "  phase: waiting switch capture startup"
  wait_for_switch_capture || return 1
  echo "  phase: releasing replay barrier"
  touch "$LAB_DIR/shared/replay_go"
  echo "  phase: waiting replay completion"
  wait_for_replays || return 1
  echo "  phase: stopping switch capture"
  stop_switch_capture
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
  for p in "$LAB_DIR/shared"/s1_eth*.pcap; do
    [[ -f "$p" ]] || continue
    cp "$p" "$run_dir/$(basename "$p")"
  done
  local replay_failed=0 rc
  for device in "${devices[@]}"; do
    copy_if_exists "$LAB_DIR/shared/${device}_tcpreplay.log" "$run_dir/${device}_tcpreplay.log"
    copy_if_exists "$LAB_DIR/shared/${device}_tcpreplay.rc" "$run_dir/${device}_tcpreplay.rc"
    if [[ -f "$run_dir/${device}_tcpreplay.rc" ]]; then
      rc="$(tr -d '[:space:]' < "$run_dir/${device}_tcpreplay.rc")"
      if [[ "$rc" != "0" ]]; then
        echo "tcpreplay on $device exited rc=$rc; log tail:" >&2
        tail -n 5 "$run_dir/${device}_tcpreplay.log" >&2 2>/dev/null || true
        replay_failed=1
      fi
    fi
    if [[ -f "$run_dir/${device}_tcpreplay.log" ]] && grep -qiE "message too long|unable to send" "$run_dir/${device}_tcpreplay.log"; then
      echo "tcpreplay on $device reported send errors (frames larger than fabric MTU?); log tail:" >&2
      tail -n 5 "$run_dir/${device}_tcpreplay.log" >&2 || true
      replay_failed=1
    fi
  done

  kathara lclean -d "$LAB_DIR" >/dev/null 2>&1 || true

  if [[ "$replay_failed" -ne 0 && "$CAPTURE_DURATION_SEC" -eq 0 ]]; then
    echo "Replay errors detected for run=$run_index variant=$v: ingress is incomplete" >&2
    return 1
  fi

  write_metadata "$metadata_dst" "$run_index" "$v" "$started" "$finished" "$ingress_dst" "$egress_dst"

  local have_directional=0
  for p in "$run_dir"/s1_eth*_in.pcap "$run_dir"/s1_eth*_out.pcap; do
    [[ -f "$p" ]] || continue
    if [[ "$(stat -c %s "$p")" -gt 24 ]]; then
      have_directional=1
      break
    fi
  done

  if [[ "$have_directional" -ne 1 && (! -f "$ingress_dst" || ! -f "$egress_dst") ]]; then
    echo "Missing output pcaps for run=$run_index variant=$v" >&2
    echo "Debug: files currently in $LAB_DIR/shared" >&2
    ls -la "$LAB_DIR/shared" >&2 || true
    echo "Debug: files currently in $S1_DIR" >&2
    ls -la "$S1_DIR" >&2 || true
    return 1
  fi

  # 24 bytes is the minimum global pcap header size. Smaller means empty/corrupt capture.
  if [[ "$have_directional" -ne 1 && ("$(stat -c %s "$ingress_dst")" -le 24 || "$(stat -c %s "$egress_dst")" -le 24) ]]; then
    echo "Output pcaps are empty/corrupt for run=$run_index variant=$v" >&2
    echo "Debug: ingress_size=$(stat -c %s "$ingress_dst") egress_size=$(stat -c %s "$egress_dst")" >&2
    echo "Debug: Docker/Kathara permissions and tcpdump runtime should be checked." >&2
    return 1
  fi
}

echo "Running Maynard overhead collection"
echo "lab_dir=$LAB_DIR"
echo "out_dir=$OUT_DIR"
echo "runs=$RUNS variant=$VARIANT expanded=${VARIANTS_TO_RUN[*]} timeout=${REPLAY_TIMEOUT}s start_timeout=${REPLAY_START_TIMEOUT}s duration=${CAPTURE_DURATION_SEC}s"

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
echo "  python3 \"$LAB_DIR/analyze_maynard_overhead.py\" --input-dir \"$OUT_DIR\" --require-same-ingress"
