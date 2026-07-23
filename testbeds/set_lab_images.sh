#!/usr/bin/env bash
set -euo pipefail

usage() {
  cat <<'EOF'
Rewrite the container image references in the testbeds' lab.conf files so a lab
is portable to another host / Docker Hub namespace.

Two ways to specify the images:

  A) Explicit images (used by run.sh --set-lab-images):
       set_lab_images.sh --root DIR \
         --tcpreplay-image USER/tcpreplay:TAG \
         --asyncua-image   USER/asyncua:TAG

  B) Derive from a Docker Hub user + tag:
       set_lab_images.sh --root DIR --dockerhub-user USER --tag TAG \
         [--include-motra] [--include-otsec]
     This sets Maynard replay hosts to USER/tcpreplay:TAG and 1client_1server
     hosts to USER/asyncua:TAG, and (with the include flags) retags the MOTRA /
     OTSEC service images to USER/<name>:TAG.

Options:
  --root DIR             Project root (required; the dir that contains testbeds/)
  --tcpreplay-image IMG  Image for Maynard rtu*/historian replay hosts
  --asyncua-image IMG    Image for 1client_1server h1/h2 hosts
  --dockerhub-user USER  Docker Hub namespace to derive images from (mode B)
  --tag TAG              Tag to derive images with (mode B, default: v1)
  --include-motra        Also retag MOTRA *:kathara-net images to USER/<name>:TAG
  --include-otsec        Also retag OTSEC *:kathara-net images to USER/<name>:TAG
  -n, --dry-run          Print the changes without editing files
  -h, --help             Show this help

The P4 switch image (kathara/p4) is never rewritten. The script is idempotent.
EOF
}

ROOT_DIR=""
TCPREPLAY_IMAGE=""
ASYNCUA_IMAGE=""
DOCKERHUB_USER=""
TAG="v1"
INCLUDE_MOTRA=0
INCLUDE_OTSEC=0
DRY_RUN=0

while [[ $# -gt 0 ]]; do
  case "$1" in
    --root) ROOT_DIR="${2:-}"; shift 2 ;;
    --tcpreplay-image) TCPREPLAY_IMAGE="${2:-}"; shift 2 ;;
    --asyncua-image) ASYNCUA_IMAGE="${2:-}"; shift 2 ;;
    --dockerhub-user) DOCKERHUB_USER="${2:-}"; shift 2 ;;
    --tag) TAG="${2:-}"; shift 2 ;;
    --include-motra) INCLUDE_MOTRA=1; shift ;;
    --include-otsec) INCLUDE_OTSEC=1; shift ;;
    -n|--dry-run) DRY_RUN=1; shift ;;
    -h|--help) usage; exit 0 ;;
    *) echo "Unknown argument: $1" >&2; usage; exit 1 ;;
  esac
done

if [[ -z "$ROOT_DIR" ]]; then
  echo "--root is required" >&2
  exit 1
fi
if [[ ! -d "$ROOT_DIR/testbeds" ]]; then
  echo "Not a project root (missing testbeds/): $ROOT_DIR" >&2
  exit 1
fi

# Derive tcpreplay/asyncua images from user+tag when not given explicitly.
if [[ -z "$TCPREPLAY_IMAGE" && -n "$DOCKERHUB_USER" ]]; then
  TCPREPLAY_IMAGE="$DOCKERHUB_USER/tcpreplay:$TAG"
fi
if [[ -z "$ASYNCUA_IMAGE" && -n "$DOCKERHUB_USER" ]]; then
  ASYNCUA_IMAGE="$DOCKERHUB_USER/asyncua:$TAG"
fi

if [[ -z "$TCPREPLAY_IMAGE" && -z "$ASYNCUA_IMAGE" && "$INCLUDE_MOTRA" -eq 0 && "$INCLUDE_OTSEC" -eq 0 ]]; then
  echo "Nothing to do: give --tcpreplay-image/--asyncua-image or --dockerhub-user (+ optional --include-*)." >&2
  exit 1
fi

# sed-escape a replacement string (for use on the RHS of s|...|REPL|).
sed_escape() { printf '%s' "$1" | sed -e 's/[&|\\]/\\&/g'; }

# Replace the RHS of every `<dev>[image]="<old>"` line whose current value
# matches $match_regex, setting it to $new_image. Idempotent.
rewrite_images() {
  local lab_conf="$1"
  local match_regex="$2"
  local new_image="$3"
  [[ -n "$new_image" ]] || return 0
  if [[ ! -f "$lab_conf" ]]; then
    echo "  (skip, missing) $lab_conf" >&2
    return 0
  fi
  local repl; repl="$(sed_escape "$new_image")"
  # Only touch non-commented [image]= lines whose value matches match_regex.
  local prog='/^[[:space:]]*#/ {print; next}
/\[image\]=/ {
  if ($0 ~ /\[image\]="[^"]*'"$match_regex"'[^"]*"/) {
    sub(/\[image\]="[^"]*"/, "[image]=\"'"$repl"'\"")
  }
}
{print}'
  if [[ "$DRY_RUN" -eq 1 ]]; then
    echo "  [dry-run] $lab_conf: /$match_regex/ -> $new_image"
    awk "$prog" "$lab_conf" | grep -nE '\[image\]=' | sed 's/^/      /'
  else
    local tmp; tmp="$(mktemp)"
    awk "$prog" "$lab_conf" > "$tmp"
    mv "$tmp" "$lab_conf"
    echo "  updated $lab_conf: /$match_regex/ -> $new_image"
  fi
}

TB="$ROOT_DIR/testbeds"

if [[ -n "$TCPREPLAY_IMAGE" ]]; then
  echo "Maynard replay hosts -> $TCPREPLAY_IMAGE"
  rewrite_images "$TB/Maynard/lab.conf" "tcpreplay" "$TCPREPLAY_IMAGE"
fi
if [[ -n "$ASYNCUA_IMAGE" ]]; then
  echo "1client_1server hosts -> $ASYNCUA_IMAGE"
  rewrite_images "$TB/1client_1server/lab.conf" "asyncua" "$ASYNCUA_IMAGE"
fi

# Retag MOTRA / OTSEC service images to USER/<name>:TAG (name = current basename
# without any tag). Requires --dockerhub-user.
retag_kathara_net() {
  local lab_conf="$1"
  [[ -f "$lab_conf" ]] || { echo "  (skip, missing) $lab_conf" >&2; return 0; }
  if [[ -z "$DOCKERHUB_USER" ]]; then
    echo "  --include-* requires --dockerhub-user; skipping $lab_conf" >&2
    return 0
  fi
  # Collect the distinct current image values (excluding kathara/p4 and comments).
  local imgs img name new
  mapfile -t imgs < <(awk -F'"' '/^[[:space:]]*#/ {next} /\[image\]=/ {print $2}' "$lab_conf" | sort -u)
  for img in "${imgs[@]}"; do
    [[ -z "$img" ]] && continue
    [[ "$img" == "kathara/p4" ]] && continue
    case "$img" in "$DOCKERHUB_USER/"*) continue ;; esac   # already namespaced
    name="${img##*/}"; name="${name%%:*}"
    new="$DOCKERHUB_USER/${name}:${TAG}"
    rewrite_images "$lab_conf" "$(printf '%s' "$img" | sed 's/[.[\*^$/]/\\&/g')" "$new"
  done
}

if [[ "$INCLUDE_MOTRA" -eq 1 ]]; then
  echo "MOTRA service images -> $DOCKERHUB_USER/<name>:$TAG"
  retag_kathara_net "$TB/motra/simple-water-treatment-plant/kathara-single-dev-p4/lab.conf"
fi
if [[ "$INCLUDE_OTSEC" -eq 1 ]]; then
  echo "OTSEC service images -> $DOCKERHUB_USER/<name>:$TAG"
  retag_kathara_net "$TB/ot-security-testbed/kathara-otsec-p4/lab.conf"
fi

echo "Done."
