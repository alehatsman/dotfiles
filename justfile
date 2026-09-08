# Machine provisioning. Replaces the mooncake `tasks.yml` task runner —
# task running is a non-goal for provision (docs/migration.md §6).
#
# Each apply recipe appends a JSON run log to ~/.local/state/provision/.
# `--json` puts one object per line on stdout and moves the human output
# to stderr, so the terminal still shows progress while the shell keeps
# the record (D9). There is no `--log` flag and there will not be one:
# redirection is the shell's job.

default:
    @just --list

x1:
    mkdir -p ~/.local/state/provision
    provision apply x1.yml --json >> ~/.local/state/provision/x1.jsonl

main_pc:
    mkdir -p ~/.local/state/provision
    provision apply main_pc.yml --json >> ~/.local/state/provision/main_pc.jsonl

mini_pc:
    mkdir -p ~/.local/state/provision
    provision apply mini_pc.yml --json >> ~/.local/state/provision/mini_pc.jsonl

mac:
    mkdir -p ~/.local/state/provision
    provision apply mac.yml --json >> ~/.local/state/provision/mac.jsonl

work_mac:
    mkdir -p ~/.local/state/provision
    provision apply work_mac.yml --json >> ~/.local/state/provision/work_mac.jsonl

# Plan one machine, e.g. `just plan x1`
plan m:
    provision plan {{m}}.yml

# Parse + render every machine plan without touching the host.
ci:
    #!/usr/bin/env bash
    set -euo pipefail
    for m in main_pc mini_pc x1 mac work_mac; do
        echo "== $m"
        provision plan --plan-no-probe "$m.yml"
    done

# Deliberate full system upgrade. NOT part of apply — a distro upgrade is
# a choice, not declared state (docs/migration.md §2).
upgrade:
    #!/usr/bin/env bash
    set -euo pipefail
    if command -v pacman >/dev/null; then sudo pacman -Syu
    elif command -v apt-get >/dev/null; then sudo apt-get update && sudo apt-get upgrade -y
    elif command -v brew >/dev/null; then brew update && brew upgrade
    else echo "no known package manager" >&2; exit 1
    fi

# Snapshot rc files to ~/.dotfiles-backup/<timestamp>/
backup:
    #!/usr/bin/env bash
    set -euo pipefail
    ts=$(date +%Y%m%d_%H%M%S)
    dest="$HOME/.dotfiles-backup/$ts"
    mkdir -p "$dest"
    for f in .zshrc .tmux.conf .gitconfig; do
        if [ -f "$HOME/$f" ]; then
            cp "$HOME/$f" "$dest/$f"
            echo "Backed up ~/$f"
        fi
    done
    echo "Backup complete in $dest/"
