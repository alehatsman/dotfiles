# Machine provisioning. Replaces the mooncake `tasks.yml` task runner —
# task running is a non-goal for provision (docs/migration.md §6).

default:
    @just --list

x1:
    provision apply x1.yml

main_pc:
    provision apply main_pc.yml

mini_pc:
    provision apply mini_pc.yml

mac:
    provision apply mac.yml

work_mac:
    provision apply work_mac.yml

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
