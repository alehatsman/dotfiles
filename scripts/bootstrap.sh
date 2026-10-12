#!/usr/bin/env bash
# Bootstrap: get `provision` onto a machine that does not have it.
#
# Everything else in this repo assumes `provision` is already on PATH. This
# script is the one step that cannot, because alehatsman/provision publishes
# no releases — there is no checksummed tarball to fetch the way
# components/nvim fetches tree-sitter. So: build from source.
#
#   ./scripts/bootstrap.sh             install provision, print next step
#   ./scripts/bootstrap.sh mini_pc     install, then apply ./mini_pc.yml
#
# Env:
#   PROVISION_REF   git ref to build (default: provision_ref in
#                   shared/variables.yml, which is `main`)
#   PREFIX          install dir (default ~/.local/bin)
#   FORCE           set to 1 to rebuild even if already current
#
# Re-running is cheap: it skips the build when the installed commit already
# matches the remote ref.
set -euo pipefail

say() { printf '\033[1m==>\033[0m %s\n' "$*"; }
die() { printf '\033[31merror:\033[0m %s\n' "$*" >&2; exit 1; }

PROVISION_REPO="https://github.com/alehatsman/provision"
PREFIX="${PREFIX:-$HOME/.local/bin}"

# The ref lives in shared/variables.yml so this script and
# components/provision read the same value. awk, because this runs before
# provision exists to parse its own vars.
repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
pinned="$(awk -F'"' '/^provision_ref:/ {print $2; exit}' \
          "$repo_root/shared/variables.yml" 2>/dev/null || true)"
[ -n "$pinned" ] || die "no provision_ref in $repo_root/shared/variables.yml"
PROVISION_REF="${PROVISION_REF:-$pinned}"

# Which commit is installed. The binary cannot tell us: Cargo.toml has read
# 0.9.1 across many commits, so `provision --version` reports the same string
# for builds that differ in which actions they support. The stamp is the only
# reliable record.
STAMP="${STAMP:-$HOME/.local/state/provision/installed-ref}"

# Resolve the ref to a commit up front, so "already current" is a real
# comparison rather than a string match on the word "main".
want_sha="$(git ls-remote "$PROVISION_REPO" "$PROVISION_REF" 2>/dev/null | awk '{print $1; exit}')"
[ -n "$want_sha" ] || die "cannot resolve $PROVISION_REF on $PROVISION_REPO (offline?)"

need_install=yes
if [ "${FORCE:-0}" = 1 ]; then
    say "FORCE=1 — rebuilding"
elif command -v provision >/dev/null 2>&1; then
    stamped="$(cat "$STAMP" 2>/dev/null || true)"
    if [ "$stamped" = "$want_sha" ]; then
        say "provision at ${want_sha:0:12} already installed at $(command -v provision)"
        need_install=no
    elif [ -n "$stamped" ]; then
        say "provision at ${stamped:0:12} installed, $PROVISION_REF is now ${want_sha:0:12} — rebuilding"
    else
        say "provision installed but unstamped (origin unknown) — rebuilding"
    fi
else
    say "provision not found — installing $PROVISION_REF (${want_sha:0:12})"
fi

if [ "$need_install" = yes ]; then
    # Rust toolchain. Install only if absent — never upgrade someone's
    # existing toolchain as a side effect of bootstrapping.
    if ! command -v cargo >/dev/null 2>&1; then
        say "no cargo — installing rust via rustup"
        command -v curl >/dev/null 2>&1 || die "curl is required to install rust"
        curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs \
            | sh -s -- -y --default-toolchain stable --profile default
        # shellcheck disable=SC1091
        . "$HOME/.cargo/env"
    fi
    command -v cargo >/dev/null 2>&1 || die "cargo still not on PATH after rustup"

    # Build in a temp clone: bootstrap leaves no source tree behind to go stale.
    tmp="$(mktemp -d)"
    trap 'rm -rf "$tmp"' EXIT

    # Fetch the resolved commit, not the ref, so the thing built is exactly
    # the thing checked above even if main moves mid-run.
    say "fetching $PROVISION_REPO at ${want_sha:0:12}"
    git init -q "$tmp/provision"
    git -C "$tmp/provision" remote add origin "$PROVISION_REPO"
    git -C "$tmp/provision" fetch -q --depth 1 origin "$want_sha" \
        || die "fetch failed for $want_sha"
    git -C "$tmp/provision" checkout -q FETCH_HEAD

    say "building (this takes a few minutes)"
    ( cd "$tmp/provision" && cargo build --release ) || die "cargo build failed"

    built="$tmp/provision/target/release/provision"
    [ -x "$built" ] || die "expected binary at $built, not found"

    mkdir -p "$PREFIX"
    # Temp name then rename: atomic, and avoids ETXTBSY if the target is
    # currently executing.
    install -m 755 "$built" "$PREFIX/.provision.new"
    mv -f "$PREFIX/.provision.new" "$PREFIX/provision"
    # Stamp AFTER the binary lands, so a failed install never claims success.
    mkdir -p "$(dirname "$STAMP")"
    printf '%s\n' "$want_sha" > "$STAMP"
    say "installed $PREFIX/provision at ${want_sha:0:12}"
fi

case ":$PATH:" in
    *":$PREFIX:"*) ;;
    *) say "note: $PREFIX is not on PATH — add it:"
       # shellcheck disable=SC2016  # $PATH is literal on purpose here
       printf '\n    export PATH="%s:$PATH"\n\n' "$PREFIX" ;;
esac

"$PREFIX/provision" --version

if [ $# -eq 0 ]; then
    cat <<EOF

Next:
    export PATH="$PREFIX:\$PATH"
    provision plan ./<machine>.yml
    provision apply ./<machine>.yml --ask-sudo-pass
EOF
    exit 0
fi

machine="$1"
plan="./${machine}.yml"
[ -f "$plan" ] || die "no such plan: $plan (run from the repo root)"

say "applying $plan"
exec "$PREFIX/provision" apply "$plan"
