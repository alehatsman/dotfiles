#!/usr/bin/env bash
# Bootstrap: get `provision` onto a machine that does not have it.
#
# Everything else in this repo assumes `provision` is already on PATH. This
# script is the one step that cannot, because alehatsman/provision publishes
# no releases — there is no checksummed tarball to fetch the way
# components/nvim fetches tree-sitter. So: build from source at a pinned tag.
#
#   ./scripts/bootstrap.sh             install provision, print next step
#   ./scripts/bootstrap.sh mini_pc     install, then apply ./mini_pc.yml
#
# Env:
#   PROVISION_REF   git ref to build (default below)
#   PREFIX          install dir (default ~/.local/bin)
#
# Idempotent: re-running with the pinned version already installed is a no-op.
set -euo pipefail

# The pin lives in shared/variables.yml, so this script and
# components/provision's assert read the same number and cannot drift. Read
# with awk because this runs before provision exists to parse its own vars.
#
# Pinned to a tag, not `main`: two machines bootstrapped a month apart must
# get the same binary. Bumping it is a deliberate commit, same posture as the
# pinned tree-sitter/zk/lazygit versions in components/nvim and components/cli.
repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
pinned="$(awk -F'"' '/^provision_version:/ {print $2; exit}' \
          "$repo_root/shared/variables.yml" 2>/dev/null || true)"
[ -n "$pinned" ] || pinned="0.9.1"   # fallback if run detached from the repo

PROVISION_REF="${PROVISION_REF:-v$pinned}"
PROVISION_REPO="https://github.com/alehatsman/provision"
PREFIX="${PREFIX:-$HOME/.local/bin}"

say() { printf '\033[1m==>\033[0m %s\n' "$*"; }
die() { printf '\033[31merror:\033[0m %s\n' "$*" >&2; exit 1; }

# The version string provision prints is bare ("provision 0.9.1"), while the
# pin is a tag ("v0.9.1"). Compare on the number alone.
want_version="${PROVISION_REF#v}"

# Decide once, explicitly, whether a build is needed.
need_install=yes
if command -v provision >/dev/null 2>&1; then
    have="$(provision --version 2>/dev/null | awk '{print $2}')"
    if [ "$have" = "$want_version" ]; then
        say "provision $have already installed at $(command -v provision)"
        need_install=no
    else
        say "provision ${have:-unknown} installed, want $want_version — replacing"
    fi
else
    say "provision not found — installing $want_version"
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

    # Build in a temp clone, not in the user's projects dir: bootstrap should
    # leave no source tree behind to go stale.
    tmp="$(mktemp -d)"
    trap 'rm -rf "$tmp"' EXIT

    say "cloning $PROVISION_REPO at $PROVISION_REF"
    git clone --depth 1 --branch "$PROVISION_REF" "$PROVISION_REPO" "$tmp/provision" \
        || die "clone failed — is $PROVISION_REF a valid tag?"

    say "building (this takes a few minutes)"
    ( cd "$tmp/provision" && cargo build --release ) || die "cargo build failed"

    built="$tmp/provision/target/release/provision"
    [ -x "$built" ] || die "expected binary at $built, not found"

    mkdir -p "$PREFIX"
    # Install to a temp name then rename: atomic, and avoids ETXTBSY if the
    # target is currently executing.
    install -m 755 "$built" "$PREFIX/.provision.new"
    mv -f "$PREFIX/.provision.new" "$PREFIX/provision"
    say "installed $PREFIX/provision"
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
