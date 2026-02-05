#!/bin/bash
set -e

# Default values
CONFIG="./main.yml"
VARS="./personal_variables.yml"
DRY_RUN=""
TAGS=""
SUDO_PASS=""

# Parse arguments
while [[ $# -gt 0 ]]; do
  case $1 in
    --work) VARS="./work_variables.yml"; shift ;;
    --dry-run) DRY_RUN="--dry-run"; shift ;;
    --tags) TAGS="--tags $2"; shift 2 ;;
    -h|--help)
      echo "Usage: $0 [OPTIONS]"
      echo "Options:"
      echo "  --work      Use work_variables.yml"
      echo "  --dry-run   Preview changes only"
      echo "  --tags TAG  Run specific tags"
      exit 0
      ;;
    *) echo "Unknown option: $1"; exit 1 ;;
  esac
done

# Build command
CMD="mooncake run -c $CONFIG -v $VARS"

if [[ -n "$DRY_RUN" ]]; then
  CMD="$CMD $DRY_RUN"
else
  if [[ -f .sudo ]]; then
    CMD="$CMD -s $(cat .sudo) --insecure-sudo-pass"
  fi
fi

[[ -n "$TAGS" ]] && CMD="$CMD $TAGS"

echo "Running: $CMD"
$CMD
