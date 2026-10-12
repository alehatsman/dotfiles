# Machine provisioning. Replaces the old `tasks.yml` task runner —
# task running is a non-goal for provision.
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

pixel:
    mkdir -p ~/.local/state/provision
    provision apply pixel.yml --json >> ~/.local/state/provision/pixel.jsonl

# Plan one machine, e.g. `just plan x1`
plan m:
    provision plan {{m}}.yml

# One implementation, shared with the pre-push hook, so the two can never
# disagree about what "validated" means. The machine list is derived from
# machines/*/ rather than written down here -- a written list drifts, which
# is how pixel ended up missing from codefort.yml's CI.

# Parse + render every machine plan without touching the host
ci:
    ./scripts/validate.sh

# scripts/bootstrap.sh does this automatically; this recipe is for a checkout
# that was cloned without running it.

# Install the pre-push validation hook into this checkout
hooks:
    #!/usr/bin/env bash
    set -euo pipefail
    common_dir=$(git rev-parse --git-common-dir)
    [[ $common_dir = /* ]] || common_dir="$PWD/$common_dir"
    mkdir -p "$common_dir/hooks"
    target="$common_dir/hooks/pre-push"
    if [[ -e $target && ! -L $target ]]; then
        echo "$target exists and is not a symlink — leaving it alone" >&2
        exit 1
    fi
    # Relative: <common_dir>/hooks/../../ is the main checkout, so this
    # survives running `just hooks` from a worktree that later goes away.
    ln -sfn ../../scripts/hooks/pre-push "$target"
    echo "pre-push hook installed → $target"

# NOT part of apply: a distro upgrade is a choice, not declared state.

# Deliberate full system upgrade
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
