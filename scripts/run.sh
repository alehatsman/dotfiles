#!/bin/bash
set -e

# Wrapper around `mooncake apply` / `mooncake plan` for per-machine entries.
#
#   ./scripts/run.sh --machine x1            # apply machines/x1/{index,vars}.yml
#   ./scripts/run.sh --machine main_pc --plan
#   ./scripts/run.sh --machine x1 --tags zsh,nvim
#
# Machine name controls which entry + vars file get used. `--plan` previews
# without applying. `--tags` filters to a subset.

MACHINE=""
PLAN_ONLY=""
TAGS=""

while [[ $# -gt 0 ]]; do
  case $1 in
    --machine|-m) MACHINE="$2"; shift 2 ;;
    --dry-run|--plan) PLAN_ONLY="1"; shift ;;
    --tags) TAGS="--tags $2"; shift 2 ;;
    -h|--help)
      cat <<EOF
Usage: $0 --machine <name> [--plan] [--tags <list>]

Options:
  -m, --machine NAME   Machine entry to run (x1, main_pc, mini_pc, mac)
  --plan, --dry-run    Preview changes via 'mooncake plan' (no system changes)
  --tags TAG           Filter by tags (comma-separated)

Examples:
  $0 --machine x1
  $0 --machine main_pc --plan
  $0 --machine x1 --tags zsh,nvim
EOF
      exit 0
      ;;
    *) echo "Unknown option: $1"; exit 1 ;;
  esac
done

if [[ -z "$MACHINE" ]]; then
  echo "Error: --machine <name> is required (one of: x1, main_pc, mini_pc, mac)"
  exit 1
fi

CONFIG="./machines/${MACHINE}/index.yml"
VARS_BASE="./shared/variables.yml"
VARS_MACHINE="./machines/${MACHINE}/vars.yml"

if [[ ! -f "$CONFIG" ]]; then
  echo "Error: $CONFIG not found"
  exit 1
fi
if [[ ! -f "$VARS_MACHINE" ]]; then
  echo "Error: $VARS_MACHINE not found"
  exit 1
fi

if [[ -n "$PLAN_ONLY" ]]; then
  CMD="mooncake plan -c $CONFIG -v $VARS_BASE -v $VARS_MACHINE $TAGS"
else
  # Decide whether to pass -K (prompt for sudo password). Skip it when no
  # step in the active config files mentions as_user: root, so single-tag
  # deploys like `--tags zsh` don't demand a password unnecessarily.
  BECOME_FLAG="-K"
  if ! grep -qr "as_user: root" "$CONFIG" ./shared/ "./machines/${MACHINE}/" ./components/ ./platforms/ 2>/dev/null; then
    BECOME_FLAG=""
    echo "(no root steps in scope — skipping -K)"
  fi
  CMD="mooncake apply -c $CONFIG -v $VARS_BASE -v $VARS_MACHINE $BECOME_FLAG $TAGS"
fi

echo "Running: $CMD"
eval "$CMD"
