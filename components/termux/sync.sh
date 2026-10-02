#!/usr/bin/env bash
# Mirror the Mac-side staging tree into Termux's $HOME over adb (dotfiles#31).
#
#   sync.sh check <stage> <termux_home> <termux_prefix>   exit 0 if in sync
#   sync.sh push  <stage> <termux_home> <termux_prefix>   copy + stamp
#
# Templates render on the Mac, so `expanduser` writes the Mac's $HOME into
# them; that prefix is rewritten to Termux's home before hashing. The hash
# of the rewritten tree is stamped in Termux; a matching stamp is "in sync".
# Files are only added/overwritten, never deleted. stdin goes through
# `adb shell`: `adb exec-in` exits 0 but hands run-as nothing.
set -euo pipefail
mode=$1 stage=$2 th=$3 tp=$4

tmp=$(mktemp -d)
trap 'rm -rf "$tmp"' EXIT
cp -R "$stage/." "$tmp/"
grep -rlF "$HOME" "$tmp" | while IFS= read -r f; do
  sed -i '' "s#$HOME#$th#g" "$f"
done || true

want=$(cd "$tmp" && find . -type f -print0 | sort -z | xargs -0 shasum -a 256 | shasum -a 256 | cut -c1-64)
have=$(adb shell run-as com.termux cat "$th/.cache/dotfiles-sync" 2>/dev/null | tr -d '\r' || true)

case $mode in
  check) [ "$want" = "$have" ] ;;
  push)
    COPYFILE_DISABLE=1 tar -C "$tmp" -cf - . | adb shell "run-as com.termux $tp/bin/sh -c 'umask 077; $tp/bin/tar -xf - -C $th'"
    printf '%s\n' "$want" | adb shell "run-as com.termux $tp/bin/sh -c 'mkdir -p $th/.cache && cat > $th/.cache/dotfiles-sync'"
    ;;
  *) echo "usage: $0 check|push <stage> <termux_home> <termux_prefix>" >&2; exit 2 ;;
esac
