#!/usr/bin/env bash
set -euo pipefail

usage() {
  cat <<'EOF'
Usage:
  run_otsec_overhead.sh [--lab-dir DIR] [--runs N] [--variant V] [--out-dir DIR] [--duration-sec SEC] [--warmup-sec SEC] [--start-timeout SEC] [--stimulate]

Options:
  --lab-dir DIR       Path to OT Security Kathara lab (default: directory of this script)
  --runs N            Number of paired runs (default: 3)
  --variant V         ip_forward | opcua_forward | extraction | forward | both | all (default: all)
  --out-dir DIR       Output root (default: <lab-dir>/overhead_runs_<timestamp>)
  --duration-sec SEC  Capture duration per variant run (default: 3600)
  --warmup-sec SEC    Wait after lstart before capture starts (default: 30)
  --start-timeout SEC Maximum time allowed for kathara lstart (default: 180)
  --stimulate         Actively trigger OPC UA polling from telegraf before capture
  --stimulus-timeout SEC
                     Maximum time to wait for background stimulus jobs (default: 120)
  --diagnostics MODE  off | on-failure | always (default: on-failure)
  -h, --help          Show this help

Output layout:
  <out-dir>/run_XX/<variant>/*.pcap
  <out-dir>/run_XX/<variant>/metadata.env
  <out-dir>/run_XX/<variant>/s_*.log
EOF
}

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
LAB_DIR="$SCRIPT_DIR"
CERT_DIR="$(cd "$SCRIPT_DIR/../certificates" && pwd)"
RUNS=3
VARIANT="all"
OUT_DIR=""
DURATION_SEC=3600
WARMUP_SEC=30
START_TIMEOUT_SEC=180
STIMULUS_TIMEOUT_SEC=120
DIAGNOSTICS_MODE="on-failure"
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
    --stimulus-timeout) STIMULUS_TIMEOUT_SEC="${2:-}"; shift 2 ;;
    --diagnostics) DIAGNOSTICS_MODE="${2:-}"; shift 2 ;;
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
if ! [[ "$STIMULUS_TIMEOUT_SEC" =~ ^[0-9]+$ ]] || [[ "$STIMULUS_TIMEOUT_SEC" -lt 1 ]]; then
  echo "Invalid --stimulus-timeout value: $STIMULUS_TIMEOUT_SEC" >&2
  exit 1
fi
case "$DIAGNOSTICS_MODE" in
  off|on-failure|always) ;;
  *) echo "Invalid --diagnostics value: $DIAGNOSTICS_MODE" >&2; exit 1 ;;
esac

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
if ! command -v docker >/dev/null 2>&1; then
  echo "docker command not found" >&2
  exit 1
fi
if ! command -v capinfos >/dev/null 2>&1; then
  echo "capinfos command not found (install wireshark-common)" >&2
  exit 1
fi
if ! command -v openssl >/dev/null 2>&1; then
  echo "openssl command not found" >&2
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
declare -a STIM_JOBS=()
CAPTURE_MODE_USED="unknown"

run_lclean() {
  if command -v timeout >/dev/null 2>&1; then
    timeout 60s kathara lclean -d "$LAB_DIR" >/dev/null 2>&1 || true
  else
    kathara lclean -d "$LAB_DIR" >/dev/null 2>&1 || true
  fi
}

cleanup() {
  set +e
  for sw in "${SWITCHES[@]}"; do
    kathara exec -d "$LAB_DIR" "$sw" -- sh -lc "pkill -TERM tcpdump 2>/dev/null || true; sleep 1; pkill -KILL tcpdump 2>/dev/null || true" >/dev/null 2>&1 || true
  done
  for pid in "${STIM_JOBS[@]:-}"; do
    wait "$pid" >/dev/null 2>&1 || true
  done
  run_lclean
}
trap cleanup EXIT

clear_shared_captures() {
  rm -f "$LAB_DIR/shared"/s1_eth*_in.pcap "$LAB_DIR/shared"/s1_eth*_out.pcap
  rm -f "$LAB_DIR/shared"/s1_eth*_in.tcpdump.log "$LAB_DIR/shared"/s1_eth*_out.tcpdump.log
  rm -f "$LAB_DIR/shared"/s1_eth*_any.pcap "$LAB_DIR/shared"/s1_eth*_any.tcpdump.log
  rm -f "$LAB_DIR/shared"/s1_eth*_in.pid "$LAB_DIR/shared"/s1_eth*_out.pid "$LAB_DIR/shared"/s1_eth*_any.pid
  rm -f "$LAB_DIR/shared"/telegraf_once.log "$LAB_DIR/shared"/tcp_stimulate.log
  rm -f "$LAB_DIR/shared"/thumbprints.commands
}

expected_capture_processes() {
  local total=0
  local sw
  for sw in "${SWITCHES[@]}"; do
    total=$((total + SWITCH_PORTS[$sw] * 3))
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
  for sw in "${SWITCHES[@]}"; do
    local ports="${SWITCH_PORTS[$sw]}"
    for ((p=0; p<ports; p++)); do
      for dir in in out; do
        local out="/shared/${sw}_eth${p}_${dir}.pcap"
        local log="/shared/${sw}_eth${p}_${dir}.tcpdump.log"
        local pid="/shared/${sw}_eth${p}_${dir}.pid"
        local cmd
        if [[ "$mode" == "qflag" ]]; then
          cmd="nohup tcpdump -s 0 -U -Q '$dir' -i 'eth${p}' -w '$out' 'tcp port $PORT' >'$log' 2>&1 & echo \$! > '$pid'"
        else
          local qual="inbound"
          [[ "$dir" == "out" ]] && qual="outbound"
          cmd="nohup tcpdump -s 0 -U -i 'eth${p}' -w '$out' '$qual and tcp port $PORT' >'$log' 2>&1 & echo \$! > '$pid'"
        fi
        kathara exec -d "$LAB_DIR" "$sw" -- sh -lc "$cmd" >/dev/null
      done
      local any_out="/shared/${sw}_eth${p}_any.pcap"
      local any_log="/shared/${sw}_eth${p}_any.tcpdump.log"
      local any_pid="/shared/${sw}_eth${p}_any.pid"
      kathara exec -d "$LAB_DIR" "$sw" -- sh -lc \
        "nohup tcpdump -s 0 -U -i 'eth${p}' -w '$any_out' 'tcp port $PORT' >'$any_log' 2>&1 & echo \$! > '$any_pid'" >/dev/null
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
  local sw waited running
  # Stop the INGRESS captures first ('-Q in' or BPF 'inbound') and give
  # in-flight packets time to exit: killing everything at once records ingress
  # packets whose egress copy was never captured -> fake drops at the boundary.
  for sw in "${SWITCHES[@]}"; do
    kathara exec -d "$LAB_DIR" "$sw" -- sh -lc "pkill -TERM -f 'tcpdump.*(Q in|inbound)' 2>/dev/null || true" >/dev/null 2>&1 || true
  done
  sleep 2
  for sw in "${SWITCHES[@]}"; do
    kathara exec -d "$LAB_DIR" "$sw" -- sh -lc "pkill -TERM tcpdump 2>/dev/null || true" >/dev/null 2>&1 || true
  done
  waited=0
  while (( waited < 15 )); do
    sleep 1
    waited=$((waited + 1))
    running="$(running_tcpdump_processes)"
    if [[ "$running" =~ ^[0-9]+$ ]] && (( running == 0 )); then
      echo "  tcpdump stopped cleanly"
      return 0
    fi
  done
  echo "  tcpdump still running after TERM; sending KILL"
  for sw in "${SWITCHES[@]}"; do
    kathara exec -d "$LAB_DIR" "$sw" -- sh -lc "pkill -KILL tcpdump 2>/dev/null || true" >/dev/null 2>&1 || true
  done
  sleep 1
}

copy_if_exists() {
  local src="$1"
  local dst="$2"
  [[ -f "$src" ]] && cp "$src" "$dst"
}

pcap_has_packets() {
  local pcap="$1"
  [[ -f "$pcap" ]] || return 1
  [[ "$(stat -c %s "$pcap" 2>/dev/null || echo 0)" -gt 24 ]]
}

packet_count() {
  local pcap="$1"
  capinfos -c "$pcap" 2>/dev/null | awk -F: '/Number of packets/ {gsub(/^[ \t]+/, "", $2); print $2; exit}'
}

sha1_thumb_der() {
  local cert_path="$1"
  local fp
  fp="$(openssl x509 -inform DER -in "$cert_path" -noout -fingerprint -sha1 | awk -F= '{print $2}' | tr -d ':' | tr 'A-Z' 'a-z')"
  echo "0x${fp}"
}

# Export the certificates actually present inside the running containers.
# They are the ones that appear on the wire; the host-side
# certificates/applications tree is gitignored and may be absent or stale on a
# deployment machine (regenerating it would NOT change the certs baked into
# the images, silently desynchronizing the thumbprint table).
export_runtime_certs() {
  local export_dir="$LAB_DIR/shared/certs_export"
  rm -rf "$export_dir"
  mkdir -p "$export_dir"

  kathara exec -d "$LAB_DIR" openplc -- sh -lc \
    'cp /workdir/OpenPLC_v3/etc/PKI/own/certs/plc.crt.der /shared/certs_export/plc.crt.der' >/dev/null 2>&1 || true
  kathara exec -d "$LAB_DIR" telegraf -- sh -lc \
    'cp /opt/otsec/certs/telegraf.crt /shared/certs_export/telegraf.crt.pem' >/dev/null 2>&1 || true
  kathara exec -d "$LAB_DIR" industrial_process -- sh -lc \
    'cp /usr/src/simulator/industrial-process.der /shared/certs_export/industrial-process.crt.der' >/dev/null 2>&1 || true

  # Normalize PEM exports to DER so a single thumbprint routine handles all.
  local pem
  for pem in "$export_dir"/*.pem; do
    [[ -f "$pem" ]] || continue
    openssl x509 -in "$pem" -outform DER -out "${pem%.pem}.der" 2>/dev/null || rm -f "$pem"
    rm -f "$pem"
  done
}

program_cert_thumbprints() {
  local v="$1"
  local run_dir="$2"
  local cmd_file="$LAB_DIR/shared/thumbprints.commands"
  local cert thumb count
  local export_dir="$LAB_DIR/shared/certs_export"

  if [[ "$v" != "extraction" ]]; then
    return 0
  fi

  export_runtime_certs

  local -a cert_files=()
  for cert in "$export_dir"/*.der; do
    [[ -f "$cert" ]] || continue
    cert_files+=("$cert")
  done

  if [[ "${#cert_files[@]}" -eq 0 ]]; then
    echo "WARNING: could not export certificates from running containers; falling back to $CERT_DIR/applications" >&2
    echo "         (fallback thumbprints match the wire only if these are the exact files used at image build time)" >&2
    for cert in "$CERT_DIR"/applications/*.crt.der; do
      [[ -f "$cert" ]] || continue
      cert_files+=("$cert")
    done
  fi

  count=0
  {
    echo "table_clear thumbprint_table"
    for cert in "${cert_files[@]}"; do
      thumb="$(sha1_thumb_der "$cert")"
      echo "table_add thumbprint_table NoAction $thumb =>"
      count=$((count + 1))
    done
    echo "table_dump thumbprint_table"
  } > "$cmd_file"

  if [[ "$count" -eq 0 ]]; then
    echo "No certificate available for thumbprint_table (neither container export nor $CERT_DIR/applications)" >&2
    echo "Run: (cd \"$CERT_DIR\" && ./create-certs.sh) and REBUILD the images so wire certs and table match." >&2
    return 1
  fi

  cp "$cmd_file" "$run_dir/thumbprints.commands"
  kathara exec -d "$LAB_DIR" s1 -- sh -lc "simple_switch_CLI < /shared/thumbprints.commands" >"$run_dir/thumbprints.log" 2>&1
}

# Certificates only cross the wire during OpenSecureChannel: the OPC UA server
# must be listening BEFORE captures start, otherwise `telegraf --once` cannot
# open a channel inside the capture window and no OPN/cert is ever captured.
wait_for_opcua_server() {
  local deadline=$((SECONDS + START_TIMEOUT_SEC))
  while (( SECONDS < deadline )); do
    if kathara exec -d "$LAB_DIR" telegraf -- bash -lc "timeout 2 bash -c '</dev/tcp/10.11.0.21/$PORT'" >/dev/null 2>&1; then
      return 0
    fi
    sleep 3
  done
  echo "OPC UA server (openplc 10.11.0.21:$PORT) did not come up within ${START_TIMEOUT_SEC}s" >&2
  echo "Inspect /shared/openplc.log via: kathara exec -d \"$LAB_DIR\" openplc -- tail -50 /shared/openplc.log" >&2
  return 1
}

write_capture_summary() {
  local run_dir="$1"
  local summary="$run_dir/capture_summary.tsv"
  local f size packets

  {
    printf 'file\tsize_bytes\tpackets\n'
    for f in "$run_dir"/s1_eth*.pcap; do
      [[ -f "$f" ]] || continue
      size="$(stat -c %s "$f" 2>/dev/null || echo 0)"
      packets="$(packet_count "$f")"
      printf '%s\t%s\t%s\n' "$(basename "$f")" "$size" "${packets:-0}"
    done
  } > "$summary"
}

collect_runtime_diagnostics() {
  local run_dir="$1"
  local dev
  local devices=(
    s1 telegraf influxdb chronograf kapacitor industrial_process openplc fuxa attacker shellinabox
  )

  docker ps -a --format 'table {{.Names}}\t{{.Status}}\t{{.Image}}' \
    | grep -E '(^NAMES|kathara_)' > "$run_dir/docker_ps_after_capture.log" 2>&1 || true

  for dev in "${devices[@]}"; do
    {
      echo "### $dev runtime snapshot $(date -Iseconds)"
      local exec_cmd=(kathara exec -d "$LAB_DIR" "$dev" -- sh -lc)
      local snapshot_script='
        echo "--- hostname ---"
        hostname || true
        echo "--- ip -br addr ---"
        ip -br addr 2>/dev/null || ip addr 2>/dev/null || true
        echo "--- ip neigh ---"
        ip neigh 2>/dev/null || true
        echo "--- listeners ---"
        ss -ltnp 2>/dev/null || netstat -ltnp 2>/dev/null || true
        echo "--- tcp connections ---"
        ss -tnp 2>/dev/null || netstat -antp 2>/dev/null || true
        echo "--- processes ---"
        ps -ef 2>/dev/null || ps aux 2>/dev/null || true
        echo "--- relevant files ---"
        for p in \
          /usr/src/simulator/industrial-process.der \
          /usr/src/simulator/industrial-process.pem \
          /usr/src/simulator/telegraf.der \
          /workdir/OpenPLC_v3/etc/config.ini \
          /workdir/OpenPLC_v3/etc/PKI/own/certs/plc.crt.der \
          /workdir/OpenPLC_v3/etc/PKI/own/private/plc.key.der \
          /etc/telegraf/telegraf.conf; do
          [ -e "$p" ] && ls -l "$p" || echo "MISSING $p"
        done
      '
      if command -v timeout >/dev/null 2>&1; then
        timeout 12s "${exec_cmd[@]}" "$snapshot_script" 2>&1 || true
      else
        "${exec_cmd[@]}" "$snapshot_script" 2>&1 || true
      fi
    } > "$run_dir/${dev}_runtime.log"
  done
}

maybe_collect_diagnostics() {
  local run_dir="$1"
  local reason="$2"
  case "$DIAGNOSTICS_MODE" in
    always)
      echo "  phase: collecting diagnostics ($reason)"
      collect_runtime_diagnostics "$run_dir"
      ;;
    on-failure)
      if [[ "$reason" != "success" ]]; then
        echo "  phase: collecting diagnostics ($reason)"
        collect_runtime_diagnostics "$run_dir"
      fi
      ;;
    off)
      ;;
  esac
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
  echo "  phase: stimulate OPC UA traffic (telegraf --once loop)"
  STIM_JOBS=()

  # A single `telegraf --once` is a ~1s burst: it opens ONE fresh secure channel
  # (one OPN with the telegraf certificate) and exits, which races capture
  # startup and gives the analyzer almost nothing to see. Run it in a loop for
  # the whole capture window instead: every iteration is a NEW process => a NEW
  # OpenSecureChannel => a fresh OPN-with-certificate on the wire, and the steady
  # stream removes the start-up race. Mirrors MOTRA's continuous-traffic model.
  local stim_seconds="$DURATION_SEC"
  local remote_stim
  remote_stim='
    : > /shared/telegraf_once.log
    end=$(( $(date +%s) + '"$stim_seconds"' ))
    i=0
    while [ "$(date +%s)" -lt "$end" ]; do
      i=$(( i + 1 ))
      echo "[telegraf-stim] iter $i $(date -Iseconds)" >> /shared/telegraf_once.log
      telegraf --config /etc/telegraf/telegraf.conf --once >> /shared/telegraf_once.log 2>&1 || true
      sleep 2
    done
    echo "[telegraf-stim] done iters=$i" >> /shared/telegraf_once.log
  '
  (
    if command -v timeout >/dev/null 2>&1; then
      timeout "$((stim_seconds + 60))s" kathara exec -d "$LAB_DIR" telegraf -- sh -lc "$remote_stim" >/dev/null 2>&1 || true
    else
      kathara exec -d "$LAB_DIR" telegraf -- sh -lc "$remote_stim" >/dev/null 2>&1 || true
    fi
  ) &
  STIM_JOBS+=("$!")

  # NOTE: no bare-TCP "attacker" probe here. It produced only SYN/RST (it never
  # speaks OPC UA, so it is not a certificate source) and, worse, probing
  # endpoints that do not listen on 4840 (industrial-process) generated
  # connection-refused RSTs that tripped the analyzer's quality gate
  # (rst_total>0). The overhead measurement must see only the legitimate OPC UA
  # traffic; a rogue-connection scenario is a separate effectiveness experiment.

  echo "  stimulation launched in background"
}

wait_for_stimulus() {
  local pid start_ts now elapsed running
  start_ts="$(date +%s)"
  while true; do
    running=0
    for pid in "${STIM_JOBS[@]:-}"; do
      if kill -0 "$pid" >/dev/null 2>&1; then
        running=1
        break
      fi
    done
    if [[ "$running" -eq 0 ]]; then
      break
    fi
    now="$(date +%s)"
    elapsed=$((now - start_ts))
    if [[ "$elapsed" -ge "$STIMULUS_TIMEOUT_SEC" ]]; then
      echo "  stimulus timeout after ${STIMULUS_TIMEOUT_SEC}s; terminating background stimulus"
      for pid in "${STIM_JOBS[@]:-}"; do
        kill "$pid" >/dev/null 2>&1 || true
      done
      sleep 1
      for pid in "${STIM_JOBS[@]:-}"; do
        kill -9 "$pid" >/dev/null 2>&1 || true
      done
      break
    fi
    sleep 1
  done
  for pid in "${STIM_JOBS[@]:-}"; do
    wait "$pid" >/dev/null 2>&1 || true
  done
  STIM_JOBS=()
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
  copy_if_exists "$LAB_DIR/s1/commands.txt" "$run_dir/s1_commands.txt"
  clear_shared_captures

  started="$(date -Iseconds)"
  echo "  phase: lab cleanup/start"
  run_lclean
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
  echo "  phase: waiting for OPC UA server (openplc:$PORT)"
  if ! wait_for_opcua_server; then
    maybe_collect_diagnostics "$run_dir" "opcua-server-not-listening"
    run_lclean
    return 1
  fi
  echo "  phase: programming extraction thumbprints if needed"
  if ! program_cert_thumbprints "$v" "$run_dir"; then
    echo "Failed to program extraction thumbprints for run=$run_index variant=$v" >&2
    maybe_collect_diagnostics "$run_dir" "thumbprint-programming-failed"
    run_lclean
    return 1
  fi
  echo "  starting captures on switch s1 (tcp/$PORT)"
  if ! start_captures; then
    echo "Failed to start captures on s1 (both capture modes failed)." >&2
    echo "Inspect shared tcpdump logs under: $LAB_DIR/shared/s1_eth*_*.tcpdump.log" >&2
    stop_captures
    maybe_collect_diagnostics "$run_dir" "capture-start-failed"
    run_lclean
    return 1
  fi
  if (( STIMULATE == 1 )); then
    stimulate_traffic
  fi
  sleep_with_progress "$DURATION_SEC"
  echo "  stopping captures"
  stop_captures
  finished="$(date -Iseconds)"
  wait_for_stimulus
  maybe_collect_diagnostics "$run_dir" "success"

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
    for f in "$LAB_DIR/shared"/${sw}_eth*_any.pcap; do
      [[ -f "$f" ]] || continue
      cp "$f" "$run_dir/$(basename "$f")"
    done
    for f in "$LAB_DIR/shared"/${sw}_eth*_any.tcpdump.log; do
      [[ -f "$f" ]] || continue
      cp "$f" "$run_dir/$(basename "$f")"
    done
  done
  copy_if_exists "$LAB_DIR/shared/telegraf_once.log" "$run_dir/telegraf_once.log"
  copy_if_exists "$LAB_DIR/shared/tcp_stimulate.log" "$run_dir/tcp_stimulate.log"
  write_capture_summary "$run_dir"

  write_metadata "$run_dir/metadata.env" "$run_index" "$v" "$started" "$finished"

  local found_in=0
  local found_out=0
  for f in "$run_dir"/s1_eth*_in.pcap; do
    [[ -f "$f" ]] || continue
    if pcap_has_packets "$f"; then
      found_in=1
      break
    fi
  done
  for f in "$run_dir"/s1_eth*_out.pcap; do
    [[ -f "$f" ]] || continue
    if pcap_has_packets "$f"; then
      found_out=1
      break
    fi
  done
  if [[ "$found_in" -ne 1 || "$found_out" -ne 1 ]]; then
    local found_any=0
    for f in "$run_dir"/s1_eth*_any.pcap; do
      [[ -f "$f" ]] || continue
      if pcap_has_packets "$f"; then
        found_any=1
        break
      fi
    done
    echo "Missing valid directional pcaps for run=$run_index variant=$v (in=$found_in out=$found_out)" >&2
    if [[ "$found_any" -eq 1 ]]; then
      echo "Non-directional tcp/$PORT packets were captured, so tcpdump direction filtering (-Q/BPF in/out) is likely the problem." >&2
    else
      echo "No non-directional tcp/$PORT packets were captured on s1 either: the lab likely produced no OPC UA/TCP traffic during the window." >&2
    fi
    echo "Capture mode used: $CAPTURE_MODE_USED" >&2
    echo "Inspect: $run_dir/capture_summary.tsv" >&2
    echo "Inspect service snapshots: $run_dir/*_runtime.log" >&2
    echo "Inspect stimulus log: $run_dir/telegraf_once.log" >&2
    ls -la "$LAB_DIR/shared" >&2 || true
    maybe_collect_diagnostics "$run_dir" "missing-directional-pcaps"
    run_lclean
    return 1
  fi

  # SYN/RST probes alone also satisfy the directional check above: for the
  # extraction variant additionally require at least one OPN message carrying
  # a certificate, i.e. the packet class the whole experiment is about.
  if [[ "$v" == "extraction" ]]; then
    local extractor="$LAB_DIR/../../extract_opcua_thumbprints.py"
    local -a in_pcaps=()
    for f in "$run_dir"/s1_eth*_in.pcap; do
      [[ -f "$f" ]] || continue
      in_pcaps+=("$f")
    done
    if [[ -f "$extractor" && "${#in_pcaps[@]}" -gt 0 ]]; then
      local opn_thumbs
      opn_thumbs="$(python3 "$extractor" --port "$PORT" "${in_pcaps[@]}" 2>/dev/null | sed '/^$/d' | wc -l)"
      echo "  OPN certificates observed in ingress captures: $opn_thumbs"
      if [[ "$opn_thumbs" -eq 0 ]]; then
        echo "No OPN-with-certificate packet captured for run=$run_index variant=$v" >&2
        echo "The stimulus did not open a new secure channel inside the capture window" >&2
        echo "(check $run_dir/telegraf_once.log) or the OPN did not fit a single frame (MTU/segmentation)." >&2
        maybe_collect_diagnostics "$run_dir" "no-opn-cert-captured"
        run_lclean
        return 1
      fi
    fi
  fi

  run_lclean
}

echo "Running OT Security overhead collection"
echo "lab_dir=$LAB_DIR"
echo "out_dir=$OUT_DIR"
echo "runs=$RUNS variant=$VARIANT expanded=${VARIANTS_TO_RUN[*]} duration=${DURATION_SEC}s warmup=${WARMUP_SEC}s diagnostics=$DIAGNOSTICS_MODE"

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
echo "  python3 \"$LAB_DIR/analyze_otsec_overhead.py\" --input-dir \"$OUT_DIR\" --require-extraction-opn-cert"
