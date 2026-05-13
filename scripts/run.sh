#!/bin/bash
set -e

# Default values
CONFIG="./main.yml"
VARS="./variables.yml"
PLAN_ONLY=""
TAGS=""

# Parse arguments
while [[ $# -gt 0 ]]; do
  case $1 in
    --dry-run|--plan) PLAN_ONLY="1"; shift ;;
    --tags) TAGS="--tags $2"; shift 2 ;;
    -h|--help)
      echo "Usage: $0 [OPTIONS]"
      echo "Options:"
      echo "  --dry-run|--plan  Preview changes via 'mooncake plan' (no system changes)"
      echo "  --tags TAG        Filter by tags (comma-separated)"
      exit 0
      ;;
    *) echo "Unknown option: $1"; exit 1 ;;
  esac
done

# Build command. Spec 16: `mooncake plan` for preview, `mooncake apply` for execute.
if [[ -n "$PLAN_ONLY" ]]; then
  CMD="mooncake plan -c $CONFIG -v $VARS $TAGS"
else
  CMD="mooncake apply -c $CONFIG -v $VARS -K $TAGS"
fi

echo "Running: $CMD"
$CMD
