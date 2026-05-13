#!/usr/bin/env bash
set -euo pipefail

usage() {
  cat <<'EOF'
Usage:
  run_cert_size_overhead.sh [--lab-dir DIR] [--runs N] [--variant V] [--out-dir DIR]
                            [--key-bits-list CSV] [--sessions N] [--session-timeout SEC]
                            [--warmup-sec SEC] [--mtu N]

Options:
  --lab-dir DIR          Testbed directory (default: script directory)
  --runs N               Paired runs per certificate size (default: 3)
  --variant V            forward | extraction | both (default: both)
  --out-dir DIR          Output root (default: <lab-dir>/overhead_cert_<timestamp>)
  --key-bits-list CSV    RSA key sizes to sweep (default: 1024,2048,3072,4096)
  --sessions N           Client sessions per run/variant (default: 10)
  --session-timeout SEC  Timeout per client session (default: 40)
  --warmup-sec SEC       Wait after lab start (default: 15)
  --mtu N                MTU on h1/h2/s1 interfaces; 0 keeps current MTU (default: 9000)
  -h, --help             Show this help

Output layout:
  <out-dir>/run_XX/k<key_bits>/<variant>/*.pcap
  <out-dir>/run_XX/k<key_bits>/<variant>/metadata.env
  <out-dir>/run_XX/k<key_bits>/<variant>/switch.log
EOF
}

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
LAB_DIR="$SCRIPT_DIR"
RUNS=3
VARIANT="both"
OUT_DIR=""
KEY_BITS_LIST="1024,2048,3072,4096"
SESSIONS=10
SESSION_TIMEOUT=40
WARMUP_SEC=15
MTU=9000
PORT=4840

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
    -h|--help) usage; exit 0 ;;
    *) echo "Unknown argument: $1" >&2; usage; exit 1 ;;
  esac
done

if [[ -z "$OUT_DIR" ]]; then
  OUT_DIR="$LAB_DIR/overhead_cert_$(date +%Y%m%d_%H%M%S)"
fi

for v in RUNS SESSIONS SESSION_TIMEOUT WARMUP_SEC MTU; do
  if ! [[ "${!v}" =~ ^[0-9]+$ ]]; then
    echo "Invalid numeric value for $v: ${!v}" >&2
    exit 1
  fi
done

if [[ "$RUNS" -lt 1 || "$SESSIONS" -lt 1 || "$SESSION_TIMEOUT" -lt 1 ]]; then
  echo "runs/sessions/session-timeout must be >= 1" >&2
  exit 1
fi

case "$VARIANT" in
  forward|extraction|both) ;;
  *) echo "Invalid --variant value: $VARIANT" >&2; exit 1 ;;
esac

for required in \
  "$LAB_DIR/lab.conf" \
  "$LAB_DIR/s1.startup" \
  "$LAB_DIR/set_p4_variant.sh" \
  "$LAB_DIR/s1/update_thumbprints.sh" \
  "$LAB_DIR/s1/start_captures.sh" \
  "$LAB_DIR/s1/stop_captures.sh" \
  "$LAB_DIR/h1/generate_client_cert.py"; do
  if [[ ! -f "$required" ]]; then
    echo "Missing required file: $required" >&2
    exit 1
  fi
done

for cmd in kathara openssl python3 capinfos; do
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

prepare_key_material() {
  local bits="$1"

  openssl genpkey -algorithm RSA -pkeyopt "rsa_keygen_bits:${bits}" -out "$LAB_DIR/h1/client-private-key.pem" >/dev/null 2>&1
  openssl genpkey -algorithm RSA -pkeyopt "rsa_keygen_bits:${bits}" -out "$LAB_DIR/h2/server-private-key.pem" >/dev/null 2>&1

  rm -f \
    "$LAB_DIR/h1/client-certificate.der" \
    "$LAB_DIR/h2/server-certificate.der" \
    "$LAB_DIR/h1/certificates/trusted/certs/server-certificate.der" \
    "$LAB_DIR/shared/server-certificate.der" \
    "$LAB_DIR/shared/client-certificate.der"
}

pcap_count() {
  local pcap="$1"
  capinfos -c "$pcap" 2>/dev/null | awk -F: '/Number of packets/ {gsub(/^[ \t]+/, "", $2); print $2; exit}'
}

set_mtu_if_needed() {
  if [[ "$MTU" -eq 0 ]]; then
    return 0
  fi

  kathara exec -d "$LAB_DIR" h1 -- ip link set dev eth0 mtu "$MTU" >/dev/null
  kathara exec -d "$LAB_DIR" h2 -- ip link set dev eth0 mtu "$MTU" >/dev/null
  kathara exec -d "$LAB_DIR" s1 -- ip link set dev eth0 mtu "$MTU" >/dev/null
  kathara exec -d "$LAB_DIR" s1 -- ip link set dev eth1 mtu "$MTU" >/dev/null
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
  prepare_key_material "$bits"

  "$LAB_DIR/set_p4_variant.sh" "$variant" >/dev/null

  kathara lclean -d "$LAB_DIR" >/dev/null 2>&1 || true
  kathara lstart -d "$LAB_DIR" --noterminals >/dev/null

  if [[ "$WARMUP_SEC" -gt 0 ]]; then
    echo "  warmup ${WARMUP_SEC}s"
    sleep "$WARMUP_SEC"
  fi

  set_mtu_if_needed

  # Wait for server startup to generate its certificate in h2 container filesystem.
  local cert_ready=0
  for _ in $(seq 1 40); do
    if kathara exec -d "$LAB_DIR" h2 -- test -s /server-certificate.der >/dev/null 2>&1; then
      cert_ready=1
      break
    fi
    sleep 1
  done
  if [[ "$cert_ready" -ne 1 ]]; then
    echo "Server certificate was not generated in h2 for run=$run_index bits=$bits variant=$variant" >&2
    return 1
  fi

  # Ensure client cert exists before thumbprint programming.
  kathara exec -d "$LAB_DIR" h1 -- python3 generate_client_cert.py >"$run_dir/client_cert.log" 2>&1

  # Export certs to shared host-visible path.
  kathara exec -d "$LAB_DIR" h2 -- cp /server-certificate.der /shared/server-certificate.der >/dev/null
  kathara exec -d "$LAB_DIR" h1 -- cp /client-certificate.der /shared/client-certificate.der >/dev/null

  server_cert="$LAB_DIR/shared/server-certificate.der"
  client_cert="$LAB_DIR/shared/client-certificate.der"
  if [[ ! -s "$server_cert" || ! -s "$client_cert" ]]; then
    echo "Missing exported certificate(s) for run=$run_index bits=$bits variant=$variant" >&2
    return 1
  fi

  # Update trusted peer certs inside containers.
  kathara exec -d "$LAB_DIR" h1 -- cp /shared/server-certificate.der /certificates/trusted/certs/server-certificate.der >/dev/null
  kathara exec -d "$LAB_DIR" h2 -- cp /shared/client-certificate.der /certificates/trusted/certs/client-certificate.der >/dev/null

  server_thumb="$(sha1_thumb_der "$server_cert")"
  client_thumb="$(sha1_thumb_der "$client_cert")"
  server_bytes="$(stat -c %s "$server_cert")"
  client_bytes="$(stat -c %s "$client_cert")"

  if [[ "$variant" == "extraction" ]]; then
    kathara exec -d "$LAB_DIR" s1 -- bash /update_thumbprints.sh "$server_thumb" "$client_thumb" >"$run_dir/thumbprints.log" 2>&1
  fi

  kathara exec -d "$LAB_DIR" s1 -- bash /start_captures.sh "$PORT" >"$run_dir/capture_start.log" 2>&1
  sleep 2

  sessions_ok=0
  sessions_fail=0
  local session_idx
  for ((session_idx=1; session_idx<=SESSIONS; session_idx++)); do
    local slog="$run_dir/session_$(printf '%03d' "$session_idx").log"
    if timeout "${SESSION_TIMEOUT}s" kathara exec -d "$LAB_DIR" h1 -- python3 ua_client_with_encryption.py >"$slog" 2>&1; then
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
      if [[ "$(stat -c %s "$p")" -ge 24 ]]; then
        echo "$(basename "$p" .pcap)_packets=$(pcap_count "$p")"
      fi
    done
  } > "$run_dir/metadata.env"

  local valid=0
  for p in "$run_dir"/s1_eth*.pcap; do
    [[ -f "$p" ]] || continue
    if [[ "$(stat -c %s "$p")" -ge 24 ]]; then
      valid=1
      break
    fi
  done
  if [[ "$valid" -ne 1 ]]; then
    echo "No valid captures for run=$run_index bits=$bits variant=$variant" >&2
    return 1
  fi

  kathara lclean -d "$LAB_DIR" >/dev/null
}

declare -a KEY_BITS=()
split_csv_numbers "$KEY_BITS_LIST" KEY_BITS

echo "Running certificate-size overhead collection"
echo "lab_dir=$LAB_DIR"
echo "out_dir=$OUT_DIR"
echo "runs=$RUNS variant=$VARIANT"
echo "key_bits_list=${KEY_BITS[*]}"
echo "sessions=$SESSIONS session_timeout=${SESSION_TIMEOUT}s warmup=${WARMUP_SEC}s mtu=$MTU"

for bits in "${KEY_BITS[@]}"; do
  for ((i=1; i<=RUNS; i++)); do
    if [[ "$VARIANT" == "both" ]]; then
      echo "[run $i/$RUNS][key $bits] variant=forward"
      run_variant_once "$i" "$bits" "forward"
      echo "[run $i/$RUNS][key $bits] variant=extraction"
      run_variant_once "$i" "$bits" "extraction"
    else
      echo "[run $i/$RUNS][key $bits] variant=$VARIANT"
      run_variant_once "$i" "$bits" "$VARIANT"
    fi
  done
done

echo "Collection completed."
echo "Output directory: $OUT_DIR"
echo "Next step:"
echo "  python3 \"$LAB_DIR/analyze_cert_size_overhead.py\" --input-dir \"$OUT_DIR\""
