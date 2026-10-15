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
# Windows machines get a second check: the host plan, ./<m>.host.yml.
#
# The machine list is DERIVED from machines/*/, not written down. A list
# written down is a list that drifts: pixel was missing from codefort.yml's
# CI for exactly that reason. Adding machines/<m>/ is all it takes to be
# covered here.
#
# provision.yml is checked too, and separately. It is the root dispatcher --
# the entrypoint a real `provision apply provision.yml` uses -- and it was
# the one file nothing validated: an ungated shell step in
# components/nvim/copilot.yml failed `provision validate ./provision.yml`
# while all six machine plans rendered clean, so the hook passed a tree the
# dispatcher could not parse. Validating the machines is not the same claim
# as validating the thing that routes to them.
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
checked=0

# check <label> <plan> [provision args...] — both stages for one plan.
check() {
  local label="$1"; shift
  checked=$((checked + 1))
  printf '== %-16s validate ' "$label"
  if out="$(provision validate "$@" 2>&1)"; then
    printf 'ok   plan '
  else
    printf 'FAILED\n%s\n' "$out" >&2
    failed+=("$label")
    return 0
  fi
  if out="$(provision plan --plan-no-probe "$@" 2>&1)"; then
    echo 'ok'
  else
    printf 'FAILED\n%s\n' "$out" >&2
    failed+=("$label")
  fi
}

# provision run ON Windows judges `sudo:` and `service` against the reading
# host, even with `--var os=linux`, so no Linux or mac plan validates there
# (provision 9c046ef). Those are reported as skipped, never silently dropped;
# WSL, Linux or a mac still covers them.
on_windows=false
case "$(uname -s)" in MINGW*|MSYS*|CYGWIN*) on_windows=true ;; esac
skipped=()

# The dispatcher first: a break here means no machine is reachable at all,
# which is worth reporting before six per-machine results scroll past it.
# Validate only, as before: it has no plan of its own to render.
if $on_windows; then
  printf '== %-16s skipped (not validatable from Windows; run from WSL)\n' 'dispatcher'
  skipped+=('provision.yml')
else
  checked=$((checked + 1))
  printf '== %-16s validate ' 'dispatcher'
  if out="$(provision validate ./provision.yml 2>&1)"; then
    echo 'ok'
  else
    printf 'FAILED\n%s\n' "$out" >&2
    failed+=('provision.yml')
  fi
fi

for m in "${machines[@]}"; do
  if $on_windows; then
    printf '== %-16s skipped (not validatable from Windows; run from WSL)\n' "$m"
    skipped+=("$m")
    continue
  fi
  check "$m" "./$m.yml"
done

# Windows HOST plans: ./<m>.host.yml. A Windows machine's ./<m>.yml is its
# WSL guest; the host side went unchecked until this stage and sat failing
# `validate` with six ungated shell steps. A machine whose index imports
# platforms/windows without a host root is a defect, same rule as above.
for m in "${machines[@]}"; do
  if grep -q 'platforms/windows/' "machines/$m/index.yml" 2>/dev/null && [ ! -f "$m.host.yml" ]; then
    echo "validate: $m is a Windows machine but $m.host.yml does not exist" >&2
    exit 1
  fi
done
for f in *.host.yml; do
  [ -e "$f" ] || continue
  check "${f%.yml}" "./$f"
done

if [ ${#failed[@]} -gt 0 ]; then
  echo >&2
  echo "validate: ${#failed[@]} of $checked plans failed: ${failed[*]}" >&2
  exit 1
fi

echo
echo "validate: all $checked plans render clean"
if [ ${#skipped[@]} -gt 0 ]; then
  echo "validate: ${#skipped[@]} skipped on Windows: ${skipped[*]}"
fi
