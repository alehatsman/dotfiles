#!/usr/bin/env bash
# Validate every machine plan without touching the host.
#
# The single implementation behind both `just ci` and the pre-push hook
# (scripts/hooks/pre-push). One copy, so the two can never disagree about
# what "validated" means.
#
# Two stages, cheapest first:
#   validate  — parses every imported file and renders every template.
#               Errors carry file:line:col.
#   plan      — --plan-no-probe: static expansion, no system reads. Catches
#               undefined vars, bad imports, unknown action keys.
#
# Both run on any host for any machine, so a mac checks mainpc's config.
#
# The machine list is DERIVED from machines/*/, not written down. A list
# written down is a list that drifts: pixel was missing from codefort.yml's
# CI for exactly that reason. Adding machines/<m>/ is all it takes to be
# covered here.
set -euo pipefail

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$repo_root"

if ! command -v provision >/dev/null 2>&1; then
  echo "validate: provision not on PATH — run ./scripts/bootstrap.sh" >&2
  exit 1
fi

machines=()
for d in machines/*/; do
  m="$(basename "$d")"
  # A machine directory is only checkable through its root entrypoint, which
  # is what loads its vars. Missing one is a real defect, not a reason to
  # quietly skip: provision.yml dispatches on these names.
  if [ ! -f "$m.yml" ]; then
    echo "validate: machines/$m/ exists but $m.yml does not" >&2
    exit 1
  fi
  machines+=("$m")
done

if [ ${#machines[@]} -eq 0 ]; then
  echo "validate: no machines found under machines/" >&2
  exit 1
fi

failed=()

for m in "${machines[@]}"; do
  printf '== %-10s validate ' "$m"
  if out="$(provision validate "./$m.yml" 2>&1)"; then
    printf 'ok   plan '
  else
    printf 'FAILED\n%s\n' "$out" >&2
    failed+=("$m")
    continue
  fi
  if out="$(provision plan --plan-no-probe "./$m.yml" 2>&1)"; then
    echo 'ok'
  else
    printf 'FAILED\n%s\n' "$out" >&2
    failed+=("$m")
  fi
done

if [ ${#failed[@]} -gt 0 ]; then
  echo >&2
  echo "validate: ${#failed[@]} of ${#machines[@]} machine plans failed: ${failed[*]}" >&2
  exit 1
fi

echo
echo "validate: all ${#machines[@]} machine plans render clean"
