#!/usr/bin/env sh
# Put a *working* mooncake on this machine, from nothing.
#
#   sh scripts/install_mooncake.sh
#
# Env:
#   INSTALL_DIR  where the binary lands      (default ~/.local/bin, no sudo)
#   VERSION      release tag to try          (default latest)
#   MOONCAKE_SRC source checkout for builds  (default ~/projects/mooncake)
#   FORCE=1      reinstall even if a working mooncake is already present
#
# Two things make this more than a curl|tar:
#
#   1. OS/arch detection. The old version hardcoded Linux_x86_64, so it
#      handed a Linux ELF to every mac.
#   2. A release is only accepted if it can actually parse THIS repo.
#      Releases lag main by months (v0.6.0 shipped 2026-05 and rejects
#      `vars.load`/`import`, which every machine entrypoint here uses),
#      so a version check alone can't tell you the binary is usable.
#      We install it, ask it to validate a real machine config, and fall
#      back to building from source when it can't — bootstrapping a Go
#      toolchain into a cache dir if the box has no Go yet.
#
# No sudo anywhere: the default INSTALL_DIR is user-owned. That also
# keeps the first apply's `-K` prompt the only password you type.

set -eu

REPO="alehatsman/mooncake"
INSTALL_DIR="${INSTALL_DIR:-$HOME/.local/bin}"
VERSION="${VERSION:-latest}"
MOONCAKE_SRC="${MOONCAKE_SRC:-$HOME/projects/mooncake}"
CACHE_DIR="${XDG_CACHE_HOME:-$HOME/.cache}/mooncake-bootstrap"
REPO_ROOT=$(CDPATH='' cd -- "$(dirname -- "$0")/.." && pwd)

info() { printf '\033[1;34m==> \033[0m%s\n' "$*"; }
ok()   { printf '\033[1;32m ✓  \033[0m%s\n' "$*"; }
warn() { printf '\033[1;33m ⚠  \033[0m%s\n' "$*" >&2; }
die()  { printf '\033[1;31mERROR: \033[0m%s\n' "$*" >&2; exit 1; }

command -v curl >/dev/null 2>&1 || die "curl is required"
command -v tar  >/dev/null 2>&1 || die "tar is required"

# ── platform ────────────────────────────────────────────────────────────
case "$(uname -s)" in
  Darwin) OS=Darwin ;;
  Linux)  OS=Linux  ;;
  *)      die "unsupported OS: $(uname -s) (Windows: use the release zip)" ;;
esac

case "$(uname -m)" in
  arm64|aarch64) ARCH=arm64;  GOARCH=arm64 ;;
  x86_64|amd64)  ARCH=x86_64; GOARCH=amd64 ;;
  armv7l|armv7)  ARCH=armv7;  GOARCH=arm   ;;
  i386|i686)     ARCH=i386;   GOARCH=386   ;;
  *)             die "unsupported architecture: $(uname -m)" ;;
esac
[ "$OS" = Darwin ] && GOOS=darwin || GOOS=linux

# The config used to prove a binary understands this repo. Any machine
# entrypoint exercises the same syntax (vars.load + import + use/props).
for candidate in "$( [ "$OS" = Darwin ] && echo mac.yml || echo x1.yml )" \
                 mac.yml x1.yml main_pc.yml mini_pc.yml; do
  if [ -f "$REPO_ROOT/$candidate" ]; then PROBE_CONFIG="$REPO_ROOT/$candidate"; break; fi
done
[ -n "${PROBE_CONFIG:-}" ] || die "no machine entrypoint found in $REPO_ROOT"

# Does this binary understand the repo? Not "does it run" — a stale
# release runs fine and then rejects every playbook here.
usable() {
  [ -x "$1" ] || return 1
  "$1" validate -c "$PROBE_CONFIG" >/dev/null 2>&1
}

report_and_exit() {
  ok "mooncake $("$1" --version 2>/dev/null | head -1) at $1"
  case ":$PATH:" in
    *":$(dirname -- "$1"):"*) ;;
    *) warn "$(dirname -- "$1") is not on PATH — add it, or open a new shell after the first apply." ;;
  esac
  exit 0
}

# ── already good? ───────────────────────────────────────────────────────
if [ "${FORCE:-0}" != 1 ]; then
  for existing in "$INSTALL_DIR/mooncake" "$(command -v mooncake 2>/dev/null || true)"; do
    [ -n "$existing" ] || continue
    if usable "$existing"; then
      info "mooncake already installed and understands this repo"
      report_and_exit "$existing"
    fi
  done
fi

mkdir -p "$INSTALL_DIR" "$CACHE_DIR"

# ── 1. try the release ──────────────────────────────────────────────────
ASSET="mooncake_${OS}_${ARCH}.tar.gz"
if [ "$VERSION" = latest ]; then
  URL="https://github.com/$REPO/releases/latest/download/$ASSET"
else
  URL="https://github.com/$REPO/releases/download/$VERSION/$ASSET"
fi

info "Trying release: $ASSET ($VERSION)"
if curl -fsSL -o "$CACHE_DIR/$ASSET" "$URL" 2>/dev/null &&
   tar -xzf "$CACHE_DIR/$ASSET" -C "$CACHE_DIR" mooncake 2>/dev/null; then
  install -m 0755 "$CACHE_DIR/mooncake" "$INSTALL_DIR/mooncake"
  rm -f "$CACHE_DIR/mooncake" "$CACHE_DIR/$ASSET"
  if usable "$INSTALL_DIR/mooncake"; then
    ok "release binary validates against $(basename "$PROBE_CONFIG")"
    report_and_exit "$INSTALL_DIR/mooncake"
  fi
  warn "release $("$INSTALL_DIR/mooncake" --version 2>/dev/null | head -1) cannot parse $(basename "$PROBE_CONFIG") — building from source"
else
  warn "no release asset for $OS/$ARCH — building from source"
fi

# ── 2. build from source ────────────────────────────────────────────────
command -v git >/dev/null 2>&1 || die "git is required to build from source"

GO=$(command -v go 2>/dev/null || true)
if [ -z "$GO" ] && [ -x "$CACHE_DIR/go/bin/go" ]; then GO="$CACHE_DIR/go/bin/go"; fi
if [ -z "$GO" ]; then
  info "No Go toolchain — fetching one into $CACHE_DIR"
  GOVER=$(curl -fsSL "https://go.dev/dl/?mode=json" | sed -n 's/.*"version": *"\(go[0-9.]*\)".*/\1/p' | head -1)
  [ -n "$GOVER" ] || die "could not determine the latest Go version"
  curl -fsSL -o "$CACHE_DIR/go.tar.gz" "https://go.dev/dl/${GOVER}.${GOOS}-${GOARCH}.tar.gz" ||
    die "could not download $GOVER for ${GOOS}/${GOARCH}"
  rm -rf "$CACHE_DIR/go"
  tar -xzf "$CACHE_DIR/go.tar.gz" -C "$CACHE_DIR"
  rm -f "$CACHE_DIR/go.tar.gz"
  GO="$CACHE_DIR/go/bin/go"
  ok "$GOVER in $CACHE_DIR/go (bootstrap only — brew/pacman installs the real one later)"
fi

# https, not ssh: a fresh box has no key on GitHub yet.
if [ -d "$MOONCAKE_SRC/.git" ]; then
  info "Updating $MOONCAKE_SRC"
  git -C "$MOONCAKE_SRC" pull --ff-only --quiet || warn "pull failed — building the checkout as-is"
else
  info "Cloning mooncake into $MOONCAKE_SRC"
  mkdir -p "$(dirname -- "$MOONCAKE_SRC")"
  git clone --quiet "https://github.com/$REPO.git" "$MOONCAKE_SRC"
fi

info "Building (this takes a minute on a cold module cache)"
( cd "$MOONCAKE_SRC" && "$GO" build -o "$CACHE_DIR/mooncake-build" ./cmd ) || die "build failed"
install -m 0755 "$CACHE_DIR/mooncake-build" "$INSTALL_DIR/mooncake"
rm -f "$CACHE_DIR/mooncake-build"

usable "$INSTALL_DIR/mooncake" ||
  die "built mooncake still cannot parse $(basename "$PROBE_CONFIG") — the repo may need a newer mooncake than main provides"

ok "built from source at $(git -C "$MOONCAKE_SRC" rev-parse --short HEAD)"
report_and_exit "$INSTALL_DIR/mooncake"
