cat run.sh 
#!/usr/bin/env bash
set -euo pipefail

usage() {
  cat <<'EOF'
Run all overhead campaigns and formal checks.

Usage:
  run.sh [options]

Options:
  --root DIR                Project root (default: parent of this script)
  --results-dir DIR         Output directory for campaigns/logs (default: <root>/tests/TESTBEDS)
  --profile NAME            main | smoke (default: main)
  --tag NAME                Output suffix tag (default: profile name)
  --status-only             Print runtime/results status and exit
  --tcpreplay-image IMG     Image for Maynard replay hosts (default: loriringhio97/tcpreplay:v1)
  --asyncua-image IMG       Image for 1client_1server hosts (default: loriringhio97/asyncua:v1)
  --wireshark-image IMG     Common wireshark image (default: lscr.io/linuxserver/wireshark)
  --set-lab-images          Rewrite lab.conf image refs for Maynard + 1client_1server

  --skip-preflight          Skip tool/version checks
  --skip-clean              Skip preventive kathara lclean on all labs
  --skip-pull               Skip docker pull of common images
  --build-motra             Build MOTRA wrapper images locally
  --build-otsec             Build OTSEC images locally
  --skip-build-motra        Skip MOTRA wrapper image build
  --skip-build-otsec        Skip OTSEC certificate/image build
  --skip-maynard            Skip Maynard campaign
  --skip-motra              Skip MOTRA campaign
  --skip-otsec              Skip OTSEC campaign
  --skip-cert-size          Skip 1client_1server cert-size campaign
  --skip-formal             Skip formal verification runs

  --maynard-runs N          Override Maynard --runs
  --maynard-timeout SEC     Override Maynard --timeout
  --maynard-start-timeout SEC
                            Override Maynard --start-timeout
  --maynard-duration SEC    Override Maynard --duration-sec (0 waits for full replay)
  --motra-runs N            Override MOTRA --runs
  --motra-duration SEC      Override MOTRA --duration-sec
  --otsec-runs N            Override OTSEC --runs
  --otsec-duration SEC      Override OTSEC --duration-sec
  --cert-runs N             Override cert-size --runs
  --cert-sessions N         Override cert-size --sessions
  --cert-timeout SEC        Override cert-size --session-timeout
  --cert-key-bits CSV       Override cert-size --key-bits-list
  --cert-keygen-timeout SEC Override cert-size --keygen-timeout

  -h, --help                Show this help

Examples:
  ./testbeds/run.sh --profile smoke --tag smoke_ci
  ./testbeds/run.sh --profile smoke --set-lab-images \
    --tcpreplay-image myuser/tcpreplay:v1 \
    --asyncua-image myuser/asyncua:v1
  ./testbeds/run.sh --profile main --skip-formal
  ./testbeds/run.sh --status-only
EOF
}

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
RESULTS_DIR=""
PROFILE="main"
TAG=""
STATUS_ONLY=0

DO_PREFLIGHT=1
DO_CLEAN=1
DO_PULL=1
DO_BUILD_MOTRA=0
DO_BUILD_OTSEC=0
DO_MAYNARD=1
DO_MOTRA=1
DO_OTSEC=1
DO_CERT=1
DO_FORMAL=1
DO_SET_LAB_IMAGES=0

TCPREPLAY_IMAGE="loriringhio97/tcpreplay:v1"
ASYNCUA_IMAGE="loriringhio97/asyncua:v1"
WIRESHARK_IMAGE="lscr.io/linuxserver/wireshark"

MAYNARD_RUNS=""
MAYNARD_TIMEOUT=""
MAYNARD_START_TIMEOUT=""
MAYNARD_DURATION=""
MOTRA_RUNS=""
MOTRA_DURATION=""
OTSEC_RUNS=""
OTSEC_DURATION=""
CERT_RUNS=""
CERT_SESSIONS=""
CERT_TIMEOUT=""
CERT_KEY_BITS=""
CERT_KEYGEN_TIMEOUT=""

log() {
  printf '[%s] %s\n' "$(date '+%Y-%m-%d %H:%M:%S')" "$*"
}

require_file() {
  local path="$1"
  if [[ ! -f "$path" ]]; then
    echo "Missing required file: $path" >&2
    exit 1
  fi
}

require_dir() {
  local path="$1"
  if [[ ! -d "$path" ]]; then
    echo "Missing required directory: $path" >&2
    exit 1
  fi
}

is_number() {
  [[ "$1" =~ ^[0-9]+$ ]]
}

set_profile_defaults() {
  case "$PROFILE" in
    main)
      MAYNARD_RUNS="${MAYNARD_RUNS:-10}"
      MAYNARD_TIMEOUT="${MAYNARD_TIMEOUT:-21600}"
      MAYNARD_START_TIMEOUT="${MAYNARD_START_TIMEOUT:-300}"
      MAYNARD_DURATION="${MAYNARD_DURATION:-0}"
      MOTRA_RUNS="${MOTRA_RUNS:-3}"
      MOTRA_DURATION="${MOTRA_DURATION:-14400}"
      OTSEC_RUNS="${OTSEC_RUNS:-3}"
      OTSEC_DURATION="${OTSEC_DURATION:-14400}"
      CERT_RUNS="${CERT_RUNS:-3}"
      CERT_SESSIONS="${CERT_SESSIONS:-30}"
      CERT_TIMEOUT="${CERT_TIMEOUT:-60}"
      CERT_KEY_BITS="${CERT_KEY_BITS:-1024,2048,3072,4096}"
      CERT_KEYGEN_TIMEOUT="${CERT_KEYGEN_TIMEOUT:-300}"
      ;;
    smoke)
      MAYNARD_RUNS="${MAYNARD_RUNS:-1}"
      MAYNARD_TIMEOUT="${MAYNARD_TIMEOUT:-1800}"
      MAYNARD_START_TIMEOUT="${MAYNARD_START_TIMEOUT:-120}"
      MAYNARD_DURATION="${MAYNARD_DURATION:-300}"
      MOTRA_RUNS="${MOTRA_RUNS:-1}"
      MOTRA_DURATION="${MOTRA_DURATION:-120}"
      OTSEC_RUNS="${OTSEC_RUNS:-1}"
      OTSEC_DURATION="${OTSEC_DURATION:-120}"
      CERT_RUNS="${CERT_RUNS:-1}"
      CERT_SESSIONS="${CERT_SESSIONS:-5}"
      CERT_TIMEOUT="${CERT_TIMEOUT:-40}"
      CERT_KEY_BITS="${CERT_KEY_BITS:-2048}"
      CERT_KEYGEN_TIMEOUT="${CERT_KEYGEN_TIMEOUT:-120}"
      ;;
    *)
      echo "Invalid --profile value: $PROFILE (expected: main|smoke)" >&2
      exit 1
      ;;
  esac
}

print_status() {
  local labs=(
    "$ROOT_DIR/testbeds/Maynard"
    "$ROOT_DIR/testbeds/motra/simple-water-treatment-plant/kathara-single-dev-p4"
    "$ROOT_DIR/testbeds/ot-security-testbed/kathara-otsec-p4"
    "$ROOT_DIR/testbeds/1client_1server"
  )

  log "Kathara runtime status"
  for lab in "${labs[@]}"; do
    local out
    out="$(kathara linfo -d "$lab" 2>&1 || true)"
    if echo "$out" | grep -q "No Devices Found"; then
      echo "  - $lab: stopped"
    elif echo "$out" | grep -q "DockerDaemonConnectionError"; then
      echo "  - $lab: docker-unavailable (cannot query runtime)"
    else
      echo "  - $lab: check output below"
      echo "$out" | sed 's/^/      /'
    fi
  done

  log "Known local overhead artifacts"
  local artifacts=(
    "$ROOT_DIR/testbeds/Maynard/overhead/report.md"
    "$ROOT_DIR/testbeds/Maynard/overhead_10/report.md"
    "$ROOT_DIR/testbeds/1client_1server/overhead_cert_smoke/report.md"
    "$ROOT_DIR/testbeds/1client_1server/overhead_cert_smoke2/report.md"
  )
  for f in "${artifacts[@]}"; do
    if [[ -f "$f" ]]; then
      echo "  - FOUND: $f"
    else
      echo "  - MISSING: $f"
    fi
  done

  if [[ -d "$RESULTS_DIR" ]]; then
    log "Result directories in $RESULTS_DIR"
    find "$RESULTS_DIR" -maxdepth 1 -mindepth 1 -type d | sort | sed 's/^/  - /'
  else
    log "Results directory does not exist yet: $RESULTS_DIR"
  fi
}

run_preflight() {
  local missing=0
  local cmds=(docker kathara python3 openssl capinfos tamarin-prover maude)
  log "Preflight toolchain checks"
  for c in "${cmds[@]}"; do
    if command -v "$c" >/dev/null 2>&1; then
      echo "  - $c: $(command -v "$c")"
    else
      echo "  - $c: MISSING"
      missing=1
    fi
  done
  if [[ "$missing" -ne 0 ]]; then
    echo "Missing required command(s). Install them before running campaigns." >&2
    exit 1
  fi

  docker version >/dev/null
  kathara --version
  tamarin-prover --version
  maude --version

  local maude_version
  maude_version="$(maude --version 2>/dev/null | awk 'NR==1 {print $1}')"
  if [[ "$maude_version" == "3.2" ]]; then
    echo "WARNING: maude 3.2 is reported as unsupported by tamarin-prover checks." >&2
    echo "         Prefer one of: 2.7.1, 3.0, 3.1, 3.2.1, 3.2.2, 3.3, 3.3.1, 3.4, 3.5" >&2
  fi
}

run_clean() {
  local labs=(
    "$ROOT_DIR/testbeds/Maynard"
    "$ROOT_DIR/testbeds/motra/simple-water-treatment-plant/kathara-single-dev-p4"
    "$ROOT_DIR/testbeds/ot-security-testbed/kathara-otsec-p4"
    "$ROOT_DIR/testbeds/1client_1server"
  )
  log "Preventive cleanup (kathara lclean)"
  for lab in "${labs[@]}"; do
    echo "  - $lab"
    kathara lclean -d "$lab" >/dev/null 2>&1 || true
  done
}

run_pull_common_images() {
  local imgs=()
  local lab_conf
  local -a lab_imgs
  if [[ "$DO_MAYNARD" -eq 1 ]]; then
    lab_conf="$ROOT_DIR/testbeds/Maynard/lab.conf"
    mapfile -t lab_imgs < <(extract_lab_images "$lab_conf")
    imgs+=("${lab_imgs[@]}")
  fi
  if [[ "$DO_MOTRA" -eq 1 ]]; then
    lab_conf="$ROOT_DIR/testbeds/motra/simple-water-treatment-plant/kathara-single-dev-p4/lab.conf"
    mapfile -t lab_imgs < <(extract_lab_images "$lab_conf")
    imgs+=("${lab_imgs[@]}")
  fi
  if [[ "$DO_OTSEC" -eq 1 ]]; then
    lab_conf="$ROOT_DIR/testbeds/ot-security-testbed/kathara-otsec-p4/lab.conf"
    mapfile -t lab_imgs < <(extract_lab_images "$lab_conf")
    imgs+=("${lab_imgs[@]}")
  fi
  if [[ "$DO_CERT" -eq 1 ]]; then
    lab_conf="$ROOT_DIR/testbeds/1client_1server/lab.conf"
    mapfile -t lab_imgs < <(extract_lab_images "$lab_conf")
    imgs+=("${lab_imgs[@]}")
  fi

  local unique_imgs=()
  local img seen existing
  for img in "${imgs[@]}"; do
    seen=0
    for existing in "${unique_imgs[@]:-}"; do
      if [[ "$existing" == "$img" ]]; then
        seen=1
        break
      fi
    done
    if [[ "$seen" -eq 0 ]]; then
      unique_imgs+=("$img")
    fi
  done

  log "Ensuring common images are available"
  for img in "${unique_imgs[@]}"; do
    if docker image inspect "$img" >/dev/null 2>&1; then
      echo "  - OK local: $img"
      continue
    fi
    case "$img" in
      dashboard:kathara-net|plc-server:kathara-net|historian:kathara-net|plc-logic:kathara-net|levelsensor-server:kathara-net|water-tank-simulation:kathara-net|valve-server:kathara-net|telegraf:kathara-net|influxdb:kathara-net|chronograf:kathara-net|kapacitor:kathara-net|ot-*:kathara-net)
        echo "  - local build expected: $img"
        continue
        ;;
    esac
    echo "  - pulling: $img"
    docker pull "$img"
  done
}

extract_lab_images() {
  local lab_conf="$1"
  awk -F'"' '/\[image\]=/ {print $2}' "$lab_conf" | sed '/^$/d' | sort -u
}

ensure_image_available() {
  local image="$1"
  if docker image inspect "$image" >/dev/null 2>&1; then
    return 0
  fi
  if docker pull "$image" >/dev/null 2>&1; then
    return 0
  fi
  return 1
}

check_lab_images() {
  local lab_name="$1"
  local lab_conf="$2"
  local missing=0

  log "Checking container images for $lab_name ($lab_conf)"
  mapfile -t imgs < <(extract_lab_images "$lab_conf")
  local img
  for img in "${imgs[@]}"; do
    if ensure_image_available "$img"; then
      echo "  - OK: $img"
    else
      echo "  - MISSING (local + Docker Hub): $img" >&2
      missing=1
    fi
  done

  if [[ "$missing" -ne 0 ]]; then
    return 1
  fi
}

run_check_required_images() {
  local failed=0

  if [[ "$DO_MAYNARD" -eq 1 ]]; then
    check_lab_images "Maynard" "$ROOT_DIR/testbeds/Maynard/lab.conf" || failed=1
  fi
  if [[ "$DO_MOTRA" -eq 1 ]]; then
    check_lab_images "MOTRA" "$ROOT_DIR/testbeds/motra/simple-water-treatment-plant/kathara-single-dev-p4/lab.conf" || failed=1
  fi
  if [[ "$DO_OTSEC" -eq 1 ]]; then
    check_lab_images "OTSEC" "$ROOT_DIR/testbeds/ot-security-testbed/kathara-otsec-p4/lab.conf" || failed=1
  fi
  if [[ "$DO_CERT" -eq 1 ]]; then
    check_lab_images "1client_1server" "$ROOT_DIR/testbeds/1client_1server/lab.conf" || failed=1
  fi

  if [[ "$failed" -ne 0 ]]; then
    echo "One or more required images are missing. Push/pull them or enable local build flags." >&2
    return 1
  fi
}

run_set_lab_images() {
  local script="$ROOT_DIR/testbeds/set_lab_images.sh"
  require_file "$script"
  log "Applying custom lab image refs (Maynard + 1client_1server)"
  "$script" \
    --root "$ROOT_DIR" \
    --tcpreplay-image "$TCPREPLAY_IMAGE" \
    --asyncua-image "$ASYNCUA_IMAGE"
}

run_build_motra() {
  local d="$ROOT_DIR/testbeds/motra/simple-water-treatment-plant/kathara-single-dev-p4"
  local base_imgs=(
    "loriringhio97/motra-dashboard-kathara-net:v1"
    "loriringhio97/motra-plc-server-kathara-net:v1"
    "loriringhio97/motra-historian-kathara-net:v1"
    "loriringhio97/motra-plc-logic-kathara-net:v1"
    "loriringhio97/motra-levelsensor-server-kathara-net:v1"
    "loriringhio97/motra-water-tank-simulation-kathara-net:v1"
    "loriringhio97/motra-valve-server-kathara-net:v1"
  )

  log "Checking MOTRA base images"
  local missing=()
  local img
  for img in "${base_imgs[@]}"; do
    if ! ensure_image_available "$img"; then
      missing+=("$img")
    fi
  done
  if [[ "${#missing[@]}" -gt 0 ]]; then
    echo "WARNING: Missing MOTRA base image(s):" >&2
    for img in "${missing[@]}"; do
      echo "  - $img" >&2
    done
    echo "MOTRA wrapper build will fail unless these base images are available." >&2
    echo "Build/pull base images first, or skip --build-motra." >&2
    return 0
  fi

  log "Building MOTRA wrapper images"
  (
    cd "$d"
    ./build_kathara_images.sh
  )
}

run_build_otsec() {
  local cert_d="$ROOT_DIR/testbeds/ot-security-testbed/certificates"
  local lab_d="$ROOT_DIR/testbeds/ot-security-testbed/kathara-otsec-p4"
  log "Generating OTSEC certificates"
  (
    cd "$cert_d"
    ./create-certs.sh
  )
  log "Building OTSEC images"
  (
    cd "$lab_d"
    ./build_kathara_images.sh
  )
}

run_maynard_campaign() {
  local out="$RESULTS_DIR/maynard_overhead_${TAG}"
  local -a quality_args=(--require-same-ingress)
  if [[ "$PROFILE" == "smoke" ]]; then
    quality_args+=(--fail-on-quality)
  fi
  log "Running Maynard campaign -> $out"
  (
    cd "$ROOT_DIR/testbeds/Maynard"
    ./run_maynard_overhead.sh \
      --runs "$MAYNARD_RUNS" \
      --variant all \
      --start-timeout "$MAYNARD_START_TIMEOUT" \
      --timeout "$MAYNARD_TIMEOUT" \
      --duration-sec "$MAYNARD_DURATION" \
      --out-dir "$out"
    python3 ./analyze_maynard_overhead.py \
      --input-dir "$out" \
      --output-dir "$out" \
      "${quality_args[@]}"
  )
}

run_motra_campaign() {
  local out="$RESULTS_DIR/motra_overhead_${TAG}"
  local -a quality_args=(--require-extraction-opn-cert)
  if [[ "$PROFILE" == "smoke" ]]; then
    quality_args+=(--fail-on-quality)
  fi
  log "Running MOTRA campaign -> $out"
  (
    cd "$ROOT_DIR/testbeds/motra/simple-water-treatment-plant/kathara-single-dev-p4"
    ./run_motra_overhead.sh \
      --runs "$MOTRA_RUNS" \
      --variant all \
      --duration-sec "$MOTRA_DURATION" \
      --warmup-sec 30 \
      --out-dir "$out"
    python3 ./analyze_motra_overhead.py \
      --input-dir "$out" \
      --output-dir "$out" \
      "${quality_args[@]}"
  )
}

run_otsec_campaign() {
  local out="$RESULTS_DIR/otsec_overhead_${TAG}"
  local -a quality_args=(--require-extraction-opn-cert)
  if [[ "$PROFILE" == "smoke" ]]; then
    quality_args+=(--fail-on-quality)
  fi
  log "Running OTSEC campaign -> $out"
  (
    cd "$ROOT_DIR/testbeds/ot-security-testbed/kathara-otsec-p4"
    ./run_otsec_overhead.sh \
      --runs "$OTSEC_RUNS" \
      --variant all \
      --duration-sec "$OTSEC_DURATION" \
      --warmup-sec 30 \
      --stimulate \
      --diagnostics on-failure \
      --out-dir "$out"
    python3 ./analyze_otsec_overhead.py \
      --input-dir "$out" \
      --output-dir "$out" \
      "${quality_args[@]}"
  )
}

run_cert_campaign() {
  local out="$RESULTS_DIR/cert_size_overhead_${TAG}"
  local -a quality_args=(--require-extraction-opn-cert)
  if [[ "$PROFILE" == "smoke" ]]; then
    quality_args+=(--fail-on-quality)
  fi
  log "Running 1client_1server cert-size campaign -> $out"
  (
    cd "$ROOT_DIR/testbeds/1client_1server"
    ./run_cert_size_overhead.sh \
      --runs "$CERT_RUNS" \
      --variant all \
      --key-bits-list "$CERT_KEY_BITS" \
      --sessions "$CERT_SESSIONS" \
      --session-timeout "$CERT_TIMEOUT" \
      --keygen-timeout "$CERT_KEYGEN_TIMEOUT" \
      --warmup-sec 20 \
      --mtu 9000 \
      --out-dir "$out"
    python3 ./analyze_cert_size_overhead.py \
      --input-dir "$out" \
      --output-dir "$out" \
      "${quality_args[@]}"
  )
}

run_formal_checks() {
  local out_dir="$RESULTS_DIR"
  local formal_dir="$ROOT_DIR/formal_verification/pk-iota"

  log "Running formal verification and GDS comparison logs"
  (
    cd "$formal_dir"
    timeout 300s tamarin-prover --prove pk-iota.spthy > "$out_dir/pk_iota_proof.txt" 2>&1 || true
    timeout 300s tamarin-prover --prove opc_ua_open_secure_channel_attacks.spthy > "$out_dir/attacks_proof.txt" 2>&1 || true

    local lemmas=(
      Rogue_Client_exists_GDS_Push_Bootstrap
      Rogue_Server_exists_GDS_Push_Bootstrap
      Middleperson_exists_GDS_Push_Bootstrap
      Rogue_Client_exists_GDS_Pull_Bootstrap
      Rogue_Server_exists_GDS_Pull_Bootstrap
      Middleperson_exists_GDS_Pull_Bootstrap
    )
    local lemma
    for lemma in "${lemmas[@]}"; do
      timeout 300s tamarin-prover --prove="$lemma" gds.spthy > "$out_dir/gds_${lemma}.txt" 2>&1 || true
    done
  )

  local summary="$out_dir/formal_quick_summary.txt"
  : > "$summary"
  rg -n "summary of summaries|verified|falsified|processing time" "$out_dir/"*.txt >>"$summary" || true
  log "Formal quick summary: $summary"
  cat "$summary"
}

run_with_log() {
  local step="$1"
  local log_file="$2"
  shift 2
  log "START $step"
  local rc
  # Run each step in a strict subshell and still mirror output to console+log.
  # Using process substitution (not a pipeline) preserves the real exit code.
  set +e
  (
    set -euo pipefail
    "$@"
  ) > >(tee "$log_file") 2>&1
  rc=$?
  set -e
  if [[ "$rc" -ne 0 ]]; then
    log "FAILED $step (rc=$rc) - log: $log_file"
    return "$rc"
  fi
  log "DONE $step"
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --root) ROOT_DIR="${2:-}"; shift 2 ;;
    --results-dir) RESULTS_DIR="${2:-}"; shift 2 ;;
    --profile) PROFILE="${2:-}"; shift 2 ;;
    --tag) TAG="${2:-}"; shift 2 ;;
    --status-only) STATUS_ONLY=1; shift ;;
    --tcpreplay-image) TCPREPLAY_IMAGE="${2:-}"; shift 2 ;;
    --asyncua-image) ASYNCUA_IMAGE="${2:-}"; shift 2 ;;
    --wireshark-image) WIRESHARK_IMAGE="${2:-}"; shift 2 ;;
    --set-lab-images) DO_SET_LAB_IMAGES=1; shift ;;

    --skip-preflight) DO_PREFLIGHT=0; shift ;;
    --skip-clean) DO_CLEAN=0; shift ;;
    --skip-pull) DO_PULL=0; shift ;;
    --build-motra) DO_BUILD_MOTRA=1; shift ;;
    --build-otsec) DO_BUILD_OTSEC=1; shift ;;
    --skip-build-motra) DO_BUILD_MOTRA=0; shift ;;
    --skip-build-otsec) DO_BUILD_OTSEC=0; shift ;;
    --skip-maynard) DO_MAYNARD=0; shift ;;
    --skip-motra) DO_MOTRA=0; shift ;;
    --skip-otsec) DO_OTSEC=0; shift ;;
    --skip-cert-size) DO_CERT=0; shift ;;
    --skip-formal) DO_FORMAL=0; shift ;;

    --maynard-runs) MAYNARD_RUNS="${2:-}"; shift 2 ;;
    --maynard-timeout) MAYNARD_TIMEOUT="${2:-}"; shift 2 ;;
    --maynard-start-timeout) MAYNARD_START_TIMEOUT="${2:-}"; shift 2 ;;
    --maynard-duration) MAYNARD_DURATION="${2:-}"; shift 2 ;;
    --motra-runs) MOTRA_RUNS="${2:-}"; shift 2 ;;
    --motra-duration) MOTRA_DURATION="${2:-}"; shift 2 ;;
    --otsec-runs) OTSEC_RUNS="${2:-}"; shift 2 ;;
    --otsec-duration) OTSEC_DURATION="${2:-}"; shift 2 ;;
    --cert-runs) CERT_RUNS="${2:-}"; shift 2 ;;
    --cert-sessions) CERT_SESSIONS="${2:-}"; shift 2 ;;
    --cert-timeout) CERT_TIMEOUT="${2:-}"; shift 2 ;;
    --cert-key-bits) CERT_KEY_BITS="${2:-}"; shift 2 ;;
    --cert-keygen-timeout) CERT_KEYGEN_TIMEOUT="${2:-}"; shift 2 ;;
    -h|--help) usage; exit 0 ;;
    *)
      echo "Unknown argument: $1" >&2
      usage
      exit 1
      ;;
  esac
done

if [[ -z "$RESULTS_DIR" ]]; then
  RESULTS_DIR="$ROOT_DIR/tests/TESTBEDS"
fi
if [[ -z "$TAG" ]]; then
  TAG="$PROFILE"
fi

set_profile_defaults

for n in \
  "$MAYNARD_RUNS" "$MAYNARD_TIMEOUT" "$MAYNARD_START_TIMEOUT" \
  "$MAYNARD_DURATION" "$MOTRA_RUNS" "$MOTRA_DURATION" "$OTSEC_RUNS" "$OTSEC_DURATION" \
  "$CERT_RUNS" "$CERT_SESSIONS" "$CERT_TIMEOUT" "$CERT_KEYGEN_TIMEOUT"; do
  if ! is_number "$n"; then
    echo "Invalid numeric value: $n" >&2
    exit 1
  fi
done

require_dir "$ROOT_DIR/testbeds"
require_file "$ROOT_DIR/testbeds/Maynard/run_maynard_overhead.sh"
require_file "$ROOT_DIR/testbeds/motra/simple-water-treatment-plant/kathara-single-dev-p4/run_motra_overhead.sh"
require_file "$ROOT_DIR/testbeds/ot-security-testbed/kathara-otsec-p4/run_otsec_overhead.sh"
require_file "$ROOT_DIR/testbeds/1client_1server/run_cert_size_overhead.sh"
require_file "$ROOT_DIR/testbeds/ot-security-testbed/certificates/create-certs.sh"
require_file "$ROOT_DIR/formal_verification/pk-iota/pk-iota.spthy"
require_file "$ROOT_DIR/formal_verification/pk-iota/opc_ua_open_secure_channel_attacks.spthy"
require_file "$ROOT_DIR/formal_verification/pk-iota/gds.spthy"

log "root_dir=$ROOT_DIR"
log "results_dir=$RESULTS_DIR"
log "profile=$PROFILE tag=$TAG"
log "tcpreplay_image=$TCPREPLAY_IMAGE"
log "asyncua_image=$ASYNCUA_IMAGE"
log "wireshark_image=$WIRESHARK_IMAGE"

if [[ "$STATUS_ONLY" -eq 1 ]]; then
  print_status
  exit 0
fi

mkdir -p "$RESULTS_DIR"
LOG_DIR="$RESULTS_DIR/logs/$(date +%Y%m%d_%H%M%S)_${TAG}"
mkdir -p "$LOG_DIR"
log "logs=$LOG_DIR"

# Setup steps abort everything on failure (nothing meaningful can follow),
# campaign steps do not: a broken testbed must not cost the others' results.
if [[ "$DO_PREFLIGHT" -eq 1 ]]; then
  run_with_log "preflight" "$LOG_DIR/01_preflight.log" run_preflight
fi
if [[ "$DO_CLEAN" -eq 1 ]]; then
  run_with_log "clean" "$LOG_DIR/02_clean.log" run_clean
fi
if [[ "$DO_SET_LAB_IMAGES" -eq 1 ]]; then
  run_with_log "set_lab_images" "$LOG_DIR/03_set_lab_images.log" run_set_lab_images
fi
if [[ "$DO_PULL" -eq 1 ]]; then
  run_with_log "pull_common_images" "$LOG_DIR/04_pull.log" run_pull_common_images
fi
if [[ "$DO_BUILD_MOTRA" -eq 1 ]]; then
  run_with_log "build_motra" "$LOG_DIR/05_build_motra.log" run_build_motra
fi
if [[ "$DO_BUILD_OTSEC" -eq 1 ]]; then
  run_with_log "build_otsec" "$LOG_DIR/06_build_otsec.log" run_build_otsec
fi
run_with_log "check_required_images" "$LOG_DIR/06b_check_images.log" run_check_required_images

FAILED_CAMPAIGNS=()
run_campaign_step() {
  local step="$1"
  local log_file="$2"
  shift 2
  if ! run_with_log "$step" "$log_file" "$@"; then
    FAILED_CAMPAIGNS+=("$step")
  fi
}

if [[ "$DO_MAYNARD" -eq 1 ]]; then
  run_campaign_step "maynard" "$LOG_DIR/07_maynard.log" run_maynard_campaign
fi
if [[ "$DO_MOTRA" -eq 1 ]]; then
  run_campaign_step "motra" "$LOG_DIR/08_motra.log" run_motra_campaign
fi
if [[ "$DO_OTSEC" -eq 1 ]]; then
  run_campaign_step "otsec" "$LOG_DIR/09_otsec.log" run_otsec_campaign
fi
if [[ "$DO_CERT" -eq 1 ]]; then
  run_campaign_step "cert_size" "$LOG_DIR/10_cert_size.log" run_cert_campaign
fi
if [[ "$DO_FORMAL" -eq 1 ]]; then
  run_campaign_step "formal" "$LOG_DIR/11_formal.log" run_formal_checks
fi

if [[ "${#FAILED_CAMPAIGNS[@]}" -gt 0 ]]; then
  log "COMPLETED WITH FAILURES: ${FAILED_CAMPAIGNS[*]}"
  log "Logs: $LOG_DIR"
  exit 1
fi
log "All requested steps completed."
log "Tip: run status check with:"
echo "  $SCRIPT_DIR/run.sh --root \"$ROOT_DIR\" --results-dir \"$RESULTS_DIR\" --status-only"
