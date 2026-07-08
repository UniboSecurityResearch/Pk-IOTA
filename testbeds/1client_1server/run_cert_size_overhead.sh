#!/usr/bin/env bash
set -euo pipefail

usage() {
  cat <<'EOF'
Usage:
  run_cert_size_overhead.sh [--lab-dir DIR] [--runs N] [--variant V] [--out-dir DIR]
                            [--key-bits-list CSV] [--sessions N] [--session-timeout SEC]
                            [--warmup-sec SEC] [--mtu N] [--keygen-timeout SEC]
                            [--start-timeout SEC] [--abort-on-failure]

Options:
  --lab-dir DIR          Testbed directory (default: script directory)
  --runs N               Paired runs per certificate size (default: 3)
  --variant V            ip_forward | opcua_forward | extraction | forward | both | all (default: all)
  --out-dir DIR          Output root (default: <lab-dir>/overhead_cert_<timestamp>)
  --key-bits-list CSV    RSA key sizes to sweep (default: 1024,2048,3072,4096)
  --sessions N           Client sessions per run/variant (default: 10)
  --session-timeout SEC  Timeout per client session (default: 40)
  --warmup-sec SEC       Extra settle time after switch is ready (default: 5)
  --mtu N                MTU on h1/h2/s1 interfaces; 0 keeps current MTU (default: 9000)
                         The jumbo path is verified end-to-end (ping -M do); the run
                         fails fast with a diagnostic if the fabric drops jumbo frames.
  --keygen-timeout SEC   Timeout for each RSA key generation command (default: 300)
  --start-timeout SEC    Timeout for switch/server readiness (default: 180)
  --abort-on-failure     Stop the whole campaign at the first failed run
                         (default: record the failure and continue)
  -h, --help             Show this help

Output layout:
  <out-dir>/run_XX/k<key_bits>/<variant>/*.pcap
  <out-dir>/run_XX/k<key_bits>/<variant>/metadata.env
  <out-dir>/run_XX/k<key_bits>/<variant>/switch.log
  <out-dir>/failed_runs.txt        (only when some run failed)
EOF
}

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
LAB_DIR="$SCRIPT_DIR"
RUNS=3
VARIANT="all"
OUT_DIR=""
KEY_BITS_LIST="1024,2048,3072,4096"
SESSIONS=10
SESSION_TIMEOUT=40
WARMUP_SEC=5
MTU=9000
KEYGEN_TIMEOUT=300
START_TIMEOUT=180
ABORT_ON_FAILURE=0
PORT=4840
SERVER_IP="10.0.0.2"

while [[ $# -gt 0 ]]; do
  case "$1" in
    --lab-dir) LAB_DIR="${2:-}"; shift 2 ;;
    --runs) RUNS="${2:-}"; shift 2 ;;
    --variant) VARIANT="${2:-}"; shift 2 ;;
    --out-dir) OUT_DIR="${2:-}"; shift 2 ;;
    --key-bits-list) KEY_BITS_LIST="${2:-}"; shift 2 ;;
    --sessions) SESSIONS="${2:-}"; shift 2 ;;
    --session-timeout) SESSION_TIMEOUT="${2:-}"; shift 2 ;;
    --warmup-sec) WARMUP_SEC="${2:-}"; shift 2 ;;
    --mtu) MTU="${2:-}"; shift 2 ;;
    --keygen-timeout) KEYGEN_TIMEOUT="${2:-}"; shift 2 ;;
    --start-timeout) START_TIMEOUT="${2:-}"; shift 2 ;;
    --abort-on-failure) ABORT_ON_FAILURE=1; shift ;;
    -h|--help) usage; exit 0 ;;
    *) echo "Unknown argument: $1" >&2; usage; exit 1 ;;
  esac
done

if [[ -z "$OUT_DIR" ]]; then
  OUT_DIR="$LAB_DIR/overhead_cert_$(date +%Y%m%d_%H%M%S)"
fi

for v in RUNS SESSIONS SESSION_TIMEOUT WARMUP_SEC MTU KEYGEN_TIMEOUT START_TIMEOUT; do
  if ! [[ "${!v}" =~ ^[0-9]+$ ]]; then
    echo "Invalid numeric value for $v: ${!v}" >&2
    exit 1
  fi
done

if [[ "$RUNS" -lt 1 || "$SESSIONS" -lt 1 || "$SESSION_TIMEOUT" -lt 1 || "$KEYGEN_TIMEOUT" -lt 1 ]]; then
  echo "runs/sessions/session-timeout/keygen-timeout must be >= 1" >&2
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

for required in \
  "$LAB_DIR/lab.conf" \
  "$LAB_DIR/s1.startup" \
  "$LAB_DIR/set_p4_variant.sh" \
  "$LAB_DIR/s1/update_thumbprints.sh" \
  "$LAB_DIR/s1/start_captures.sh" \
  "$LAB_DIR/s1/stop_captures.sh" \
  "$LAB_DIR/h1/generate_client_cert.py" \
  "$LAB_DIR/h2/generate_server_cert.py" \
  "$LAB_DIR/h2/ua_server_with_encryption.py"; do
  if [[ ! -f "$required" ]]; then
    echo "Missing required file: $required" >&2
    exit 1
  fi
done

for cmd in kathara openssl python3 capinfos timeout; do
  if ! command -v "$cmd" >/dev/null 2>&1; then
    echo "Missing command: $cmd" >&2
    exit 1
  fi
done

mkdir -p "$OUT_DIR"

cleanup() {
  set +e
  kathara lclean -d "$LAB_DIR" >/dev/null 2>&1 || true
}
trap cleanup EXIT

log() {
  printf '[%s] %s\n' "$(date '+%H:%M:%S')" "$*"
}

split_csv_numbers() {
  local csv="$1"
  local -n out_arr="$2"
  out_arr=()
  IFS=',' read -r -a raw <<< "$csv"
  for item in "${raw[@]}"; do
    item="$(echo "$item" | xargs)"
    [[ -z "$item" ]] && continue
    if ! [[ "$item" =~ ^[0-9]+$ ]]; then
      echo "Invalid key size in list: $item" >&2
      exit 1
    fi
    out_arr+=("$item")
  done
  if [[ "${#out_arr[@]}" -eq 0 ]]; then
    echo "Empty key-bits list" >&2
    exit 1
  fi
}

sha1_thumb_der() {
  local cert_path="$1"
  local fp
  fp="$(openssl x509 -inform DER -in "$cert_path" -noout -fingerprint -sha1 | awk -F= '{print $2}' | tr -d ':' | tr 'A-Z' 'a-z')"
  echo "0x${fp}"
}

generate_rsa_key_cached() {
  local bits="$1"
  local role="$2"
  local key_path="$3"
  local log_file="$4"
  local tmp_key="${key_path}.tmp"

  if [[ -s "$key_path" ]]; then
    return 0
  fi

  echo "[$(date -Iseconds)] generating RSA ${bits} key for ${role}: $key_path" >>"$log_file"
  rm -f "$tmp_key"
  if ! timeout "${KEYGEN_TIMEOUT}s" openssl genrsa -out "$tmp_key" "$bits" >>"$log_file" 2>&1; then
    rm -f "$tmp_key"
    echo "RSA key generation failed or timed out after ${KEYGEN_TIMEOUT}s: role=$role bits=$bits" >&2
    echo "Inspect keygen log: $log_file" >&2
    return 1
  fi
  mv "$tmp_key" "$key_path"
}

prepare_key_material() {
  local bits="$1"
  local run_dir="$2"
  local cache_dir="$OUT_DIR/key_material/k${bits}"
  local keygen_log="$run_dir/keygen.log"

  mkdir -p "$cache_dir"

  generate_rsa_key_cached "$bits" "client" "$cache_dir/client-private-key.pem" "$keygen_log" || return 1
  generate_rsa_key_cached "$bits" "server" "$cache_dir/server-private-key.pem" "$keygen_log" || return 1

  cp "$cache_dir/client-private-key.pem" "$LAB_DIR/h1/client-private-key.pem"
  cp "$cache_dir/server-private-key.pem" "$LAB_DIR/h2/server-private-key.pem"

  rm -f \
    "$LAB_DIR/h1/client-certificate.der" \
    "$LAB_DIR/h2/server-certificate.der" \
    "$LAB_DIR/h1/certificates/trusted/certs/server-certificate.der" \
    "$LAB_DIR/h2/certificates/trusted/certs/client-certificate.der" \
    "$LAB_DIR/shared/server-certificate.der" \
    "$LAB_DIR/shared/client-certificate.der" \
    "$LAB_DIR/shared/server.log"
}

pcap_count() {
  local pcap="$1"
  capinfos -c "$pcap" 2>/dev/null | awk -F: '/Number of packets/ {gsub(/^[ \t]+/, "", $2); print $2; exit}'
}

wait_for_switch_ready() {
  local deadline=$((SECONDS + START_TIMEOUT))
  while (( SECONDS < deadline )); do
    if kathara exec -d "$LAB_DIR" s1 -- bash -lc 'pgrep -x simple_switch >/dev/null && simple_switch_CLI <<< "help" >/dev/null 2>&1'; then
      return 0
    fi
    sleep 2
  done
  echo "Switch s1 did not become ready within ${START_TIMEOUT}s (p4c compile failure? check shared/s1.log)" >&2
  return 1
}

set_and_verify_mtu() {
  local run_dir="$1"
  if [[ "$MTU" -eq 0 ]]; then
    return 0
  fi

  kathara exec -d "$LAB_DIR" h1 -- ip link set dev eth0 mtu "$MTU" >/dev/null || return 1
  kathara exec -d "$LAB_DIR" h2 -- ip link set dev eth0 mtu "$MTU" >/dev/null || return 1
  kathara exec -d "$LAB_DIR" s1 -- ip link set dev eth0 mtu "$MTU" >/dev/null || return 1
  kathara exec -d "$LAB_DIR" s1 -- ip link set dev eth1 mtu "$MTU" >/dev/null || return 1

  if [[ "$MTU" -le 1500 ]]; then
    return 0
  fi

  # Setting the MTU inside the containers is NOT sufficient: the collision-domain
  # fabric (Docker bridge / veth peers) must also pass jumbo frames, and whether it
  # does depends on the Kathara network plugin of the host. Verify end-to-end with
  # a DF probe; without jumbo frames the OPN message that carries the certificate
  # cannot reach the P4 parser in a single segment and every session stalls.
  local probe_size=$((MTU - 28))
  local attempt
  for attempt in 1 2 3; do
    # bash -lc wrapper: kathara exec intercepts bare `-c` tokens (Nuitka guard),
    # so ping's -c must not appear in kathara's own argv.
    if kathara exec -d "$LAB_DIR" h1 -- bash -lc "ping -M do -s $probe_size -c 2 -W 3 $SERVER_IP" >"$run_dir/mtu_probe.log" 2>&1; then
      return 0
    fi
    sleep 2
  done

  cat >&2 <<EOF
Jumbo-frame verification FAILED: a ${probe_size}B DF ping h1 -> h2 was dropped.
The container MTU is $MTU but the Kathara collision-domain fabric does not pass
jumbo frames on this host (typical of the Linux-bridge network plugin; the VDE
plugin usually passes them). Fix options:
  - switch Kathara to the VDE plugin:  kathara settings  (network_plugin -> kathara/katharanp_vde)
  - or raise the MTU of the kathara bridges/veths on the host
  - or rerun with --mtu 0 / --mtu 1500 (extraction variant will NOT see whole
    certificates in one frame; only ip_forward/opcua_forward stay meaningful)
Probe log: $run_dir/mtu_probe.log
EOF
  return 1
}

start_opcua_server() {
  local run_dir="$1"
  kathara exec -d "$LAB_DIR" h2 -- bash -lc 'cd / && nohup python3 ua_server_with_encryption.py > /shared/server.log 2>&1 & disown' >/dev/null 2>&1 || true

  local deadline=$((SECONDS + START_TIMEOUT))
  while (( SECONDS < deadline )); do
    if kathara exec -d "$LAB_DIR" h1 -- bash -lc "timeout 2 bash -c '</dev/tcp/$SERVER_IP/$PORT'" >/dev/null 2>&1; then
      return 0
    fi
    sleep 2
  done
  echo "OPC UA server did not listen on $SERVER_IP:$PORT within ${START_TIMEOUT}s" >&2
  cp "$LAB_DIR/shared/server.log" "$run_dir/server.log" 2>/dev/null || true
  return 1
}

run_variant_once() {
  local run_index="$1"
  local bits="$2"
  local variant="$3"
  local size_tag run_dir
  local server_cert client_cert server_thumb client_thumb
  local server_bytes client_bytes
  local sessions_ok sessions_fail

  size_tag="k${bits}"
  run_dir="$OUT_DIR/run_$(printf '%02d' "$run_index")/${size_tag}/${variant}"
  mkdir -p "$run_dir"

  echo "  preparing key material (RSA ${bits})"
  prepare_key_material "$bits" "$run_dir" || return 1

  "$LAB_DIR/set_p4_variant.sh" "$variant" >/dev/null || return 1

  kathara lclean -d "$LAB_DIR" >/dev/null 2>&1 || true
  kathara lstart -d "$LAB_DIR" --noterminals >/dev/null || return 1

  echo "  waiting for P4 switch"
  wait_for_switch_ready || { cp "$LAB_DIR/shared/s1.log" "$run_dir/switch.log" 2>/dev/null || true; return 1; }

  if [[ "$WARMUP_SEC" -gt 0 ]]; then
    sleep "$WARMUP_SEC"
  fi

  echo "  configuring MTU ($MTU) and verifying path"
  set_and_verify_mtu "$run_dir" || return 1

  # Generate BOTH certificates before the server starts: the server loads the
  # trusted client certificate exactly once (CertificateUserManager) at startup.
  echo "  generating certificates"
  kathara exec -d "$LAB_DIR" h2 -- bash -lc 'cd / && python3 generate_server_cert.py' >"$run_dir/server_cert.log" 2>&1 || {
    echo "Server certificate generation failed (see $run_dir/server_cert.log)" >&2
    return 1
  }
  kathara exec -d "$LAB_DIR" h1 -- bash -lc 'cd / && python3 generate_client_cert.py' >"$run_dir/client_cert.log" 2>&1 || {
    echo "Client certificate generation failed (see $run_dir/client_cert.log)" >&2
    return 1
  }

  # Export certs to shared host-visible path and install the trusted peers.
  # The trusted-cert directories are empty in the repo, so git does not track
  # them and they are missing on a fresh checkout: create them explicitly.
  kathara exec -d "$LAB_DIR" h1 -- mkdir -p /certificates/trusted/certs >/dev/null || return 1
  kathara exec -d "$LAB_DIR" h2 -- mkdir -p /certificates/trusted/certs >/dev/null || return 1

  kathara exec -d "$LAB_DIR" h2 -- cp /server-certificate.der /shared/server-certificate.der >/dev/null || return 1
  kathara exec -d "$LAB_DIR" h1 -- cp /client-certificate.der /shared/client-certificate.der >/dev/null || return 1

  server_cert="$LAB_DIR/shared/server-certificate.der"
  client_cert="$LAB_DIR/shared/client-certificate.der"
  if [[ ! -s "$server_cert" || ! -s "$client_cert" ]]; then
    echo "Missing exported certificate(s) for run=$run_index bits=$bits variant=$variant" >&2
    return 1
  fi

  kathara exec -d "$LAB_DIR" h1 -- cp /shared/server-certificate.der /certificates/trusted/certs/server-certificate.der >/dev/null || return 1
  kathara exec -d "$LAB_DIR" h2 -- cp /shared/client-certificate.der /certificates/trusted/certs/client-certificate.der >/dev/null || return 1

  server_thumb="$(sha1_thumb_der "$server_cert")"
  client_thumb="$(sha1_thumb_der "$client_cert")"
  server_bytes="$(stat -c %s "$server_cert")"
  client_bytes="$(stat -c %s "$client_cert")"

  if [[ "$variant" == "extraction" ]]; then
    echo "  programming thumbprint table"
    kathara exec -d "$LAB_DIR" s1 -- bash /update_thumbprints.sh "$server_thumb" "$client_thumb" >"$run_dir/thumbprints.log" 2>&1 || {
      echo "Thumbprint programming failed (see $run_dir/thumbprints.log)" >&2
      return 1
    }
    {
      echo "table_clear thumbprint_table"
      echo "table_add thumbprint_table NoAction ${server_thumb} =>"
      echo "table_add thumbprint_table NoAction ${client_thumb} =>"
      echo "table_dump thumbprint_table"
    } > "$run_dir/thumbprints.commands"
  fi

  echo "  starting OPC UA server"
  start_opcua_server "$run_dir" || return 1

  kathara exec -d "$LAB_DIR" s1 -- bash /start_captures.sh "$PORT" >"$run_dir/capture_start.log" 2>&1 || {
    echo "Capture start failed (see $run_dir/capture_start.log)" >&2
    return 1
  }
  sleep 2

  echo "  running $SESSIONS client sessions"
  sessions_ok=0
  sessions_fail=0
  local session_idx
  for ((session_idx=1; session_idx<=SESSIONS; session_idx++)); do
    local slog="$run_dir/session_$(printf '%03d' "$session_idx").log"
    if timeout "${SESSION_TIMEOUT}s" kathara exec -d "$LAB_DIR" h1 -- bash -lc 'cd / && python3 ua_client_with_encryption.py' >"$slog" 2>&1; then
      sessions_ok=$((sessions_ok + 1))
      rm -f "$slog"
    else
      sessions_fail=$((sessions_fail + 1))
    fi
  done

  kathara exec -d "$LAB_DIR" s1 -- bash /stop_captures.sh >"$run_dir/capture_stop.log" 2>&1 || true
  sleep 1

  cp "$LAB_DIR/shared/s1_eth0_in.pcap" "$run_dir/s1_eth0_in.pcap" 2>/dev/null || true
  cp "$LAB_DIR/shared/s1_eth0_out.pcap" "$run_dir/s1_eth0_out.pcap" 2>/dev/null || true
  cp "$LAB_DIR/shared/s1_eth1_in.pcap" "$run_dir/s1_eth1_in.pcap" 2>/dev/null || true
  cp "$LAB_DIR/shared/s1_eth1_out.pcap" "$run_dir/s1_eth1_out.pcap" 2>/dev/null || true
  cp "$LAB_DIR/shared/s1.log" "$run_dir/switch.log" 2>/dev/null || true
  cp "$LAB_DIR/shared/server.log" "$run_dir/server.log" 2>/dev/null || true

  {
    echo "run_index=$run_index"
    echo "variant=$variant"
    echo "key_bits=$bits"
    echo "mtu=$MTU"
    echo "port=$PORT"
    echo "sessions_total=$SESSIONS"
    echo "sessions_ok=$sessions_ok"
    echo "sessions_fail=$sessions_fail"
    echo "server_thumbprint=$server_thumb"
    echo "client_thumbprint=$client_thumb"
    echo "server_cert_bytes=$server_bytes"
    echo "client_cert_bytes=$client_bytes"
    for p in "$run_dir"/s1_eth*.pcap; do
      [[ -f "$p" ]] || continue
      echo "$(basename "$p" .pcap)_packets=$(pcap_count "$p")"
    done
  } > "$run_dir/metadata.env"

  if [[ "$sessions_ok" -eq 0 ]]; then
    echo "All $SESSIONS sessions failed for run=$run_index bits=$bits variant=$variant" >&2
    echo "Inspect: $run_dir/session_*.log and $run_dir/server.log" >&2
    return 1
  fi

  # A pcap is valid only if it contains packets: tcpdump writes its 24-byte
  # header immediately, so a size check alone passes on empty captures.
  local valid=0 count
  for p in "$run_dir"/s1_eth*.pcap; do
    [[ -f "$p" ]] || continue
    count="$(pcap_count "$p")"
    if [[ -n "$count" && "$count" -gt 0 ]]; then
      valid=1
      break
    fi
  done
  if [[ "$valid" -ne 1 ]]; then
    echo "No packets captured for run=$run_index bits=$bits variant=$variant" >&2
    return 1
  fi

  kathara lclean -d "$LAB_DIR" >/dev/null
}

declare -a KEY_BITS=()
split_csv_numbers "$KEY_BITS_LIST" KEY_BITS

echo "Running certificate-size overhead collection"
echo "lab_dir=$LAB_DIR"
echo "out_dir=$OUT_DIR"
echo "runs=$RUNS variant=$VARIANT expanded=${VARIANTS_TO_RUN[*]}"
echo "key_bits_list=${KEY_BITS[*]}"
echo "sessions=$SESSIONS session_timeout=${SESSION_TIMEOUT}s warmup=${WARMUP_SEC}s mtu=$MTU"
echo "keygen_timeout=${KEYGEN_TIMEOUT}s start_timeout=${START_TIMEOUT}s"

FAILED_RUNS=()
for bits in "${KEY_BITS[@]}"; do
  for ((i=1; i<=RUNS; i++)); do
    for variant in "${VARIANTS_TO_RUN[@]}"; do
      echo "[run $i/$RUNS][key $bits] variant=$variant"
      if ! run_variant_once "$i" "$bits" "$variant"; then
        FAILED_RUNS+=("run=$i key_bits=$bits variant=$variant")
        echo "FAILED: run=$i key_bits=$bits variant=$variant" >&2
        if [[ "$ABORT_ON_FAILURE" -eq 1 ]]; then
          printf '%s\n' "${FAILED_RUNS[@]}" > "$OUT_DIR/failed_runs.txt"
          echo "Aborting campaign (--abort-on-failure)." >&2
          exit 1
        fi
      fi
    done
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
echo "  python3 \"$LAB_DIR/analyze_cert_size_overhead.py\" --input-dir \"$OUT_DIR\" --require-extraction-opn-cert"
