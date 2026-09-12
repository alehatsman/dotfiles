#!/usr/bin/env bash
# Switch the active Claude Code OAuth credential between saved profiles
# (e.g. personal/work). Storage backend depends on platform:
#   macOS       -> Keychain item "Claude Code-credentials"
#   Linux/WSL   -> ~/.claude/.credentials.json
# Profiles are saved copies of that live credential, named per identity.
# Token contents are never printed.
set -euo pipefail

KEYCHAIN_SERVICE="Claude Code-credentials"
KEYCHAIN_PROFILE_PREFIX="Claude Code-credentials-account-"
LINUX_CRED_FILE="$HOME/.claude/.credentials.json"
LINUX_PROFILE_PREFIX="$HOME/.claude/.credentials-account-"

platform() {
  case "$(uname -s)" in
    Darwin) echo "macos" ;;
    Linux) echo "linux" ;;
    *) echo "unsupported: $(uname -s)" >&2; exit 1 ;;
  esac
}

# --- macOS (Keychain) backend ---

macos_read_live() {
  security find-generic-password -s "$KEYCHAIN_SERVICE" -w 2>/dev/null
}

macos_write_live() {
  local blob="$1"
  security add-generic-password -U -s "$KEYCHAIN_SERVICE" -a "$USER" -w "$blob"
}

macos_read_profile() {
  local name="$1"
  security find-generic-password -s "${KEYCHAIN_PROFILE_PREFIX}${name}" -w 2>/dev/null
}

macos_write_profile() {
  local name="$1" blob="$2"
  security add-generic-password -U -s "${KEYCHAIN_PROFILE_PREFIX}${name}" -a "$USER" -w "$blob"
}

macos_list_profiles() {
  security dump-keychain 2>/dev/null \
    | grep -o "\"${KEYCHAIN_PROFILE_PREFIX}[^\"]*\"" \
    | sed -E "s/\"${KEYCHAIN_PROFILE_PREFIX}([^\"]*)\"/\1/" \
    | sort -u
}

# --- Linux (file) backend ---

linux_read_live() {
  [[ -f "$LINUX_CRED_FILE" ]] && cat "$LINUX_CRED_FILE"
}

linux_write_live() {
  local blob="$1"
  local tmp
  tmp=$(mktemp "${LINUX_CRED_FILE}.XXXXXX")
  printf '%s' "$blob" > "$tmp"
  chmod 600 "$tmp"
  mv "$tmp" "$LINUX_CRED_FILE"
}

linux_read_profile() {
  local name="$1"
  local path="${LINUX_PROFILE_PREFIX}${name}.json"
  [[ -f "$path" ]] && cat "$path"
}

linux_write_profile() {
  local name="$1" blob="$2"
  local path="${LINUX_PROFILE_PREFIX}${name}.json"
  local tmp
  tmp=$(mktemp "${path}.XXXXXX")
  printf '%s' "$blob" > "$tmp"
  chmod 600 "$tmp"
  mv "$tmp" "$path"
}

linux_list_profiles() {
  local f base
  for f in "${LINUX_PROFILE_PREFIX}"*.json; do
    [[ -e "$f" ]] || continue
    base="${f#"$LINUX_PROFILE_PREFIX"}"
    echo "${base%.json}"
  done | sort -u
}

# --- Backend dispatch ---

read_live() {
  case "$(platform)" in
    macos) macos_read_live ;;
    linux) linux_read_live ;;
  esac
}

write_live() {
  case "$(platform)" in
    macos) macos_write_live "$1" ;;
    linux) linux_write_live "$1" ;;
  esac
}

read_profile() {
  case "$(platform)" in
    macos) macos_read_profile "$1" ;;
    linux) linux_read_profile "$1" ;;
  esac
}

write_profile() {
  case "$(platform)" in
    macos) macos_write_profile "$1" "$2" ;;
    linux) linux_write_profile "$1" "$2" ;;
  esac
}

list_profiles() {
  case "$(platform)" in
    macos) macos_list_profiles ;;
    linux) linux_list_profiles ;;
  esac
}

# --- Commands ---

cmd_save() {
  local name="${1:?usage: claude-account save <name>}"
  local blob
  blob=$(read_live) || true
  if [[ -z "${blob:-}" ]]; then
    echo "claude-account: no active credential found — run 'claude login' first" >&2
    exit 1
  fi
  write_profile "$name" "$blob"
  echo "claude-account: saved active credential as '$name'"
}

cmd_list() {
  list_profiles
}

cmd_switch() {
  local profiles
  profiles=$(list_profiles)
  if [[ -z "$profiles" ]]; then
    echo "claude-account: no saved profiles — run 'claude-account save <name>' first" >&2
    exit 1
  fi

  local name
  name=$(printf '%s\n' "$profiles" | fzf --reverse --prompt='claude account > ' --height=40% --border) || exit 0

  local blob
  blob=$(read_profile "$name") || true
  if [[ -z "${blob:-}" ]]; then
    echo "claude-account: profile '$name' not found" >&2
    exit 1
  fi

  write_live "$blob"
  echo "claude-account: switched to '$name'"
}

main() {
  local sub="${1:-switch}"
  [[ $# -gt 0 ]] && shift
  case "$sub" in
    save) cmd_save "$@" ;;
    list) cmd_list "$@" ;;
    switch) cmd_switch "$@" ;;
    *)
      echo "usage: claude-account {save <name>|switch|list}" >&2
      exit 1
      ;;
  esac
}

main "$@"
