#!/usr/bin/env bash
# Fuzzy-pick a Claude Code pane across all tmux sessions and jump to it.
# Bound to `prefix C-j` from .tmux.conf. Designed to be invoked inside
# `display-popup -E` — the popup closes on selection and tmux switches
# the client to the chosen session/window/pane.
set -euo pipefail

list=$(tmux list-panes -a -F \
  '#{session_name}:#{window_index}.#{pane_index}|#{pane_current_command}|#{pane_title}' \
  | awk -F'|' '$2 ~ /claude/ { printf "%-22s  %s\n", $1, $3 }')

[[ -z "$list" ]] && { tmux display-message "no claude panes"; exit 0; }

sel=$(printf '%s\n' "$list" | fzf --reverse --no-sort --prompt='claude > ' \
  --height=100% --border=none) || exit 0

target=${sel%% *}
window=${target%.*}
tmux switch-client -t "$window"
tmux select-pane -t "$target"
