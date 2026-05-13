#!/bin/bash
set -e

# Wrapper around `mooncake apply` / `mooncake plan` for per-machine entries.
#
#   ./scripts/run.sh --machine x1            # apply entries/x1.yml + vars/x1.yml
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

CONFIG="./entries/${MACHINE}.yml"
VARS_BASE="./variables.yml"
VARS_MACHINE="./vars/${MACHINE}.yml"

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
  CMD="mooncake apply -c $CONFIG -v $VARS_BASE -v $VARS_MACHINE -K $TAGS"
fi

echo "Running: $CMD"
eval "$CMD"
