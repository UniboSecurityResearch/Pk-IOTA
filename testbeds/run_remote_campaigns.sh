#!/usr/bin/env bash
set -euo pipefail

usage() {
  cat <<'EOF'
Run all overhead campaigns and formal checks on a remote server.

Usage:
  run_remote_campaigns.sh [options]

Options:
  --root DIR                Project root (default: parent of this script)
  --results-dir DIR         Output directory for campaigns/logs (default: <root>/results)
  --profile NAME            main | smoke (default: main)
  --tag NAME                Output suffix tag (default: profile name)
  --status-only             Print runtime/results status and exit

  --skip-preflight          Skip tool/version checks
  --skip-clean              Skip preventive kathara lclean on all labs
  --skip-pull               Skip docker pull of common images
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
  --motra-runs N            Override MOTRA --runs
  --motra-duration SEC      Override MOTRA --duration-sec
  --otsec-runs N            Override OTSEC --runs
  --otsec-duration SEC      Override OTSEC --duration-sec
  --cert-runs N             Override cert-size --runs
  --cert-sessions N         Override cert-size --sessions
  --cert-timeout SEC        Override cert-size --session-timeout
  --cert-key-bits CSV       Override cert-size --key-bits-list

  -h, --help                Show this help

Examples:
  ./testbeds/run_remote_campaigns.sh --profile smoke --tag smoke_ci
  ./testbeds/run_remote_campaigns.sh --profile main --skip-formal
  ./testbeds/run_remote_campaigns.sh --status-only
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
DO_BUILD_MOTRA=1
DO_BUILD_OTSEC=1
DO_MAYNARD=1
DO_MOTRA=1
DO_OTSEC=1
DO_CERT=1
DO_FORMAL=1

MAYNARD_RUNS=""
MAYNARD_TIMEOUT=""
MAYNARD_START_TIMEOUT=""
MOTRA_RUNS=""
MOTRA_DURATION=""
OTSEC_RUNS=""
OTSEC_DURATION=""
CERT_RUNS=""
CERT_SESSIONS=""
CERT_TIMEOUT=""
CERT_KEY_BITS=""

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
      MOTRA_RUNS="${MOTRA_RUNS:-3}"
      MOTRA_DURATION="${MOTRA_DURATION:-14400}"
      OTSEC_RUNS="${OTSEC_RUNS:-3}"
      OTSEC_DURATION="${OTSEC_DURATION:-14400}"
      CERT_RUNS="${CERT_RUNS:-3}"
      CERT_SESSIONS="${CERT_SESSIONS:-30}"
      CERT_TIMEOUT="${CERT_TIMEOUT:-60}"
      CERT_KEY_BITS="${CERT_KEY_BITS:-1024,2048,3072,4096}"
      ;;
    smoke)
      MAYNARD_RUNS="${MAYNARD_RUNS:-1}"
      MAYNARD_TIMEOUT="${MAYNARD_TIMEOUT:-1800}"
      MAYNARD_START_TIMEOUT="${MAYNARD_START_TIMEOUT:-120}"
      MOTRA_RUNS="${MOTRA_RUNS:-1}"
      MOTRA_DURATION="${MOTRA_DURATION:-120}"
      OTSEC_RUNS="${OTSEC_RUNS:-1}"
      OTSEC_DURATION="${OTSEC_DURATION:-120}"
      CERT_RUNS="${CERT_RUNS:-1}"
      CERT_SESSIONS="${CERT_SESSIONS:-5}"
      CERT_TIMEOUT="${CERT_TIMEOUT:-40}"
      CERT_KEY_BITS="${CERT_KEY_BITS:-2048}"
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
  local imgs=(
    "kathara/p4"
    "loriringhio97/tcpreplay"
    "loriringhio97/asyncua"
    "lscr.io/linuxserver/wireshark"
  )
  log "Pulling common images"
  for img in "${imgs[@]}"; do
    echo "  - docker pull $img"
    docker pull "$img"
  done
}

run_build_motra() {
  local d="$ROOT_DIR/testbeds/motra/simple-water-treatment-plant/kathara-single-dev-p4"
  local base_imgs=(
    "dashboard:latest"
    "plc-server:latest"
    "historian:latest"
    "plc-logic:latest"
    "levelsensor-server:latest"
    "water-tank-simulation:latest"
    "valve-server:latest"
  )

  log "Checking MOTRA base images"
  local missing=()
  local img
  for img in "${base_imgs[@]}"; do
    if ! docker image inspect "$img" >/dev/null 2>&1; then
      missing+=("$img")
    fi
  done
  if [[ "${#missing[@]}" -gt 0 ]]; then
    echo "Missing MOTRA base image(s):" >&2
    for img in "${missing[@]}"; do
      echo "  - $img" >&2
    done
    echo "Build/pull them first, then rerun." >&2
    exit 1
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
  log "Running Maynard campaign -> $out"
  (
    cd "$ROOT_DIR/testbeds/Maynard"
    ./run_maynard_overhead.sh \
      --runs "$MAYNARD_RUNS" \
      --variant both \
      --start-timeout "$MAYNARD_START_TIMEOUT" \
      --timeout "$MAYNARD_TIMEOUT" \
      --out-dir "$out"
    python3 ./analyze_maynard_overhead.py \
      --input-dir "$out" \
      --output-dir "$out"
  )
}

run_motra_campaign() {
  local out="$RESULTS_DIR/motra_overhead_${TAG}"
  log "Running MOTRA campaign -> $out"
  (
    cd "$ROOT_DIR/testbeds/motra/simple-water-treatment-plant/kathara-single-dev-p4"
    ./run_motra_overhead.sh \
      --runs "$MOTRA_RUNS" \
      --variant both \
      --duration-sec "$MOTRA_DURATION" \
      --warmup-sec 30 \
      --out-dir "$out"
    python3 ./analyze_motra_overhead.py \
      --input-dir "$out" \
      --output-dir "$out"
  )
}

run_otsec_campaign() {
  local out="$RESULTS_DIR/otsec_overhead_${TAG}"
  log "Running OTSEC campaign -> $out"
  (
    cd "$ROOT_DIR/testbeds/ot-security-testbed/kathara-otsec-p4"
    ./run_otsec_overhead.sh \
      --runs "$OTSEC_RUNS" \
      --variant both \
      --duration-sec "$OTSEC_DURATION" \
      --warmup-sec 30 \
      --out-dir "$out"
    python3 ./analyze_otsec_overhead.py \
      --input-dir "$out" \
      --output-dir "$out"
  )
}

run_cert_campaign() {
  local out="$RESULTS_DIR/cert_size_overhead_${TAG}"
  log "Running 1client_1server cert-size campaign -> $out"
  (
    cd "$ROOT_DIR/testbeds/1client_1server"
    ./run_cert_size_overhead.sh \
      --runs "$CERT_RUNS" \
      --variant both \
      --key-bits-list "$CERT_KEY_BITS" \
      --sessions "$CERT_SESSIONS" \
      --session-timeout "$CERT_TIMEOUT" \
      --warmup-sec 20 \
      --mtu 9000 \
      --out-dir "$out"
    python3 ./analyze_cert_size_overhead.py \
      --input-dir "$out" \
      --output-dir "$out"
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
  set +e
  "$@" 2>&1 | tee "$log_file"
  local rc="${PIPESTATUS[0]}"
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

    --skip-preflight) DO_PREFLIGHT=0; shift ;;
    --skip-clean) DO_CLEAN=0; shift ;;
    --skip-pull) DO_PULL=0; shift ;;
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
    --motra-runs) MOTRA_RUNS="${2:-}"; shift 2 ;;
    --motra-duration) MOTRA_DURATION="${2:-}"; shift 2 ;;
    --otsec-runs) OTSEC_RUNS="${2:-}"; shift 2 ;;
    --otsec-duration) OTSEC_DURATION="${2:-}"; shift 2 ;;
    --cert-runs) CERT_RUNS="${2:-}"; shift 2 ;;
    --cert-sessions) CERT_SESSIONS="${2:-}"; shift 2 ;;
    --cert-timeout) CERT_TIMEOUT="${2:-}"; shift 2 ;;
    --cert-key-bits) CERT_KEY_BITS="${2:-}"; shift 2 ;;
    -h|--help) usage; exit 0 ;;
    *)
      echo "Unknown argument: $1" >&2
      usage
      exit 1
      ;;
  esac
done

if [[ -z "$RESULTS_DIR" ]]; then
  RESULTS_DIR="$ROOT_DIR/results"
fi
if [[ -z "$TAG" ]]; then
  TAG="$PROFILE"
fi

set_profile_defaults

for n in \
  "$MAYNARD_RUNS" "$MAYNARD_TIMEOUT" "$MAYNARD_START_TIMEOUT" \
  "$MOTRA_RUNS" "$MOTRA_DURATION" "$OTSEC_RUNS" "$OTSEC_DURATION" \
  "$CERT_RUNS" "$CERT_SESSIONS" "$CERT_TIMEOUT"; do
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

if [[ "$STATUS_ONLY" -eq 1 ]]; then
  print_status
  exit 0
fi

mkdir -p "$RESULTS_DIR"
LOG_DIR="$RESULTS_DIR/logs/$(date +%Y%m%d_%H%M%S)_${TAG}"
mkdir -p "$LOG_DIR"
log "logs=$LOG_DIR"

if [[ "$DO_PREFLIGHT" -eq 1 ]]; then
  run_with_log "preflight" "$LOG_DIR/01_preflight.log" run_preflight
fi
if [[ "$DO_CLEAN" -eq 1 ]]; then
  run_with_log "clean" "$LOG_DIR/02_clean.log" run_clean
fi
if [[ "$DO_PULL" -eq 1 ]]; then
  run_with_log "pull_common_images" "$LOG_DIR/03_pull.log" run_pull_common_images
fi
if [[ "$DO_BUILD_MOTRA" -eq 1 ]]; then
  run_with_log "build_motra" "$LOG_DIR/04_build_motra.log" run_build_motra
fi
if [[ "$DO_BUILD_OTSEC" -eq 1 ]]; then
  run_with_log "build_otsec" "$LOG_DIR/05_build_otsec.log" run_build_otsec
fi
if [[ "$DO_MAYNARD" -eq 1 ]]; then
  run_with_log "maynard" "$LOG_DIR/06_maynard.log" run_maynard_campaign
fi
if [[ "$DO_MOTRA" -eq 1 ]]; then
  run_with_log "motra" "$LOG_DIR/07_motra.log" run_motra_campaign
fi
if [[ "$DO_OTSEC" -eq 1 ]]; then
  run_with_log "otsec" "$LOG_DIR/08_otsec.log" run_otsec_campaign
fi
if [[ "$DO_CERT" -eq 1 ]]; then
  run_with_log "cert_size" "$LOG_DIR/09_cert_size.log" run_cert_campaign
fi
if [[ "$DO_FORMAL" -eq 1 ]]; then
  run_with_log "formal" "$LOG_DIR/10_formal.log" run_formal_checks
fi

log "All requested steps completed."
log "Tip: run status check with:"
echo "  $SCRIPT_DIR/run_remote_campaigns.sh --root \"$ROOT_DIR\" --results-dir \"$RESULTS_DIR\" --status-only"
