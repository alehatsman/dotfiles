#!/usr/bin/env bash
# Drive the fleet from one box: status, pull, apply.
#
#   ./scripts/fleet.sh status          # where is every box, and at what commit
#   ./scripts/fleet.sh sync            # pull origin/main + apply, every reachable box
#   ./scripts/fleet.sh sync minipc     # just that one
#   ./scripts/fleet.sh run minipc "uptime"
#
# Reachability is over Tailscale, resolved from `tailscale status` at call
# time rather than from a hardcoded IP table -- tailnet IPs are stable per
# device but the roster is not something this repo should duplicate and let
# drift. The hostnames below are the tailnet device names.
#
# Why this exists: these applies were being driven by hand-typed ssh one
# liners, which meant the exact command varied per run and nothing recorded
# what was actually executed on a box. CLAUDE.md puts every machine change
# through this repo; the thing that performs the change belongs here too.
#
# Offline boxes are REPORTED AND SKIPPED, never silently dropped -- a sync
# that quietly covered three of five boxes and said "done" is the failure
# this is meant to prevent.
set -uo pipefail

# machine | tailnet device name | ssh user | ssh port
#
# Port 2222 on the Windows boxes: sshd runs inside the WSL guest, and under
# mirrored networking port 22 belongs to the Windows host's own OpenSSH
# (platforms/windows/index.yml).
#
# x1 and pixel are absent: x1 is not on the tailnet, and pixel is an adb
# target rather than an ssh host (machines/pixel/index.yml). Neither can be
# driven from here; both are applied locally at the box.
FLEET=(
  "main_pc|mainpc|aleh|2222"
  "mini_pc|minipc|aleh|2222"
  "mac|mac|alehatsman|22"
)

SSH_OPTS=(-o ConnectTimeout=10 -o BatchMode=yes -o StrictHostKeyChecking=accept-new)

die() { echo "fleet: $*" >&2; exit 1; }

command -v tailscale >/dev/null 2>&1 || die "tailscale not on PATH"

# Tailnet IP for a device name, or empty if it is not up.
resolve() {
  tailscale status 2>/dev/null | awk -v want="$1" '
    $2 == want {
      # Columns after the OS field carry the state; "offline" appears there.
      for (i = 5; i <= NF; i++) if ($i ~ /offline/) exit
      print $1; exit
    }'
}

remote() {
  local ip=$1 user=$2 port=$3; shift 3
  ssh "${SSH_OPTS[@]}" -p "$port" "$user@$ip" bash -lc "$(printf '%q' "$*")"
}

# Run $2 on every selected box. $1 is a human label for the banner.
each() {
  local label=$1 script=$2 only=${3:-}
  local ran=0 failed=() skipped=()

  for entry in "${FLEET[@]}"; do
    IFS='|' read -r machine device user port <<<"$entry"
    [ -n "$only" ] && [ "$only" != "$machine" ] && [ "$only" != "$device" ] && continue

    local ip; ip="$(resolve "$device")"
    if [ -z "$ip" ]; then
      echo "== $device: OFFLINE (not up on the tailnet) — skipped"
      skipped+=("$device")
      continue
    fi

    echo "== $device ($ip) — $label"
    if remote "$ip" "$user" "$port" "${script//@MACHINE@/$machine}"; then
      ran=$((ran + 1))
    else
      echo "   ^ $device FAILED (ssh or remote command exit non-zero)"
      failed+=("$device")
    fi
    echo
  done

  echo "fleet: $ran ok, ${#failed[@]} failed, ${#skipped[@]} offline"
  [ ${#failed[@]} -gt 0 ] && echo "  failed:  ${failed[*]}"
  [ ${#skipped[@]} -gt 0 ] && echo "  offline: ${skipped[*]}"
  [ ${#failed[@]} -eq 0 ]
}

cmd=${1:-status}
only=${2:-}

case "$cmd" in
  status)
    # Single-quoted on purpose: these expand on the REMOTE box, not here.
    # shellcheck disable=SC2016
    each "status" '
      cd ~/dotfiles
      printf "   repo: %s  (origin/main: %s)\n" \
        "$(git rev-parse --short HEAD)" \
        "$(git rev-parse --short origin/main 2>/dev/null || echo unknown)"
      printf "   provision: %s\n" "$(command -v provision >/dev/null && provision --version || echo MISSING)"
    ' "$only"
    ;;
  sync)
    # Single-quoted on purpose: these expand on the REMOTE box, not here.
    # shellcheck disable=SC2016
    each "pull + apply" '
      set -e
      cd ~/dotfiles
      echo "   before: $(git rev-parse --short HEAD)"
      git pull --ff-only
      echo "   after:  $(git rev-parse --short HEAD)"
      export PATH="$HOME/.local/bin:$PATH"
      provision apply ./@MACHINE@.yml 2>&1 | tail -20
    ' "$only"
    ;;
  run)
    [ $# -ge 3 ] || die "usage: fleet.sh run <machine|all> <command>"
    target=$2; shift 2
    [ "$target" = all ] && target=""
    each "run" "$*" "$target"
    ;;
  *)
    die "unknown command: $cmd (status|sync|run)"
    ;;
esac
