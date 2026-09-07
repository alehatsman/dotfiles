# dotfiles

Personal machine config. Declarative. Reproducible. One source of truth.
**Deploy only via [mooncake](components/mooncake).** Never `cp`/`ln`/hand-edit
managed destinations.

## Bootstrap a fresh machine

From nothing to provisioned. The only step that can't be automated is
putting the generated SSH public key on GitHub — the run prints it and
tells you when.

```sh
git clone https://github.com/alehatsman/dotfiles ~/dotfiles && cd ~/dotfiles
sh scripts/install_mooncake.sh          # → ~/.local/bin/mooncake, no sudo
export PATH="$HOME/.local/bin:$PATH"    # until components/zsh lands
mooncake plan -c ./<machine>.yml        # preview; works before anything exists
mooncake apply -c ./<machine>.yml -K --keep-going
```

`--keep-going` is the flag that matters on a first run: it finishes every
step it can and lists the failures at the end (still exiting non-zero)
instead of stranding the other 160 steps behind one package that went
away upstream. Re-run after fixing; every step is idempotent.

`install_mooncake.sh` detects OS/arch, and *verifies the binary can parse
this repo* before accepting it — releases lag `main` by months, so a
version check isn't enough. When the release is too old it builds from
source, fetching a Go toolchain into `~/.cache/mooncake-bootstrap` if the
box has none. Set `VERSION=` to pin a release, `INSTALL_DIR=` to move it.

Per-platform notes:

- **macOS** — `-K` is required (Rosetta, `scutil`, `defaults` run as root).
  Homebrew installs itself during the run. First apply is ~30 min plus
  cask downloads.
- **Arch** — `platforms/arch/bootstrap.sh` does the clone + install +
  apply in one shot on first boot.
- **Windows** — run `platforms/windows/bootstrap.yml` from an Admin
  PowerShell first, then the sequence above *inside* WSL.

## Deploy

```sh
mooncake task                 # list tasks
mooncake task <machine>       # apply  (x1|main_pc|mini_pc|mac|work_mac)
mooncake task <machine> -p    # plan, no changes
mooncake task <machine> -K    # apply, prompt for sudo (x1, mac, work_mac)
mooncake task backup          # snapshot rc files → ~/.dotfiles-backup
```

Direct: `mooncake apply -c ./<machine>.yml` (`plan` to preview).

## Layout

```
<machine>.yml      entrypoint: load vars → import machines/<m>/index.yml
machines/<m>/      per-host: index.yml (component set), vars.yml
components/<c>/    unit of config: index.yml + templates/*.j2
platforms/<p>/     OS-specific: arch, macos, windows
shared/            variables.yml, bootstrap.yml
scripts/           install_mooncake.sh, test-docker.sh
docs/              nvim, tmux, keybindings, windows-ssh-setup
tasks.yml          dev surface for `mooncake task`
```

## Machines

| host    | platform                | notes                          |
|---------|-------------------------|--------------------------------|
| x1      | Arch laptop, Hyprland   | `-K` for sudo                  |
| main_pc | Windows 11 + WSL2 Ubuntu| Windows host bootstrap first   |
| mini_pc | WSL                     | NOPASSWD sudo                  |
| mac     | macOS                   | `-K` for sudo                  |
| work_mac| macOS (NVIDIA work box) | `-K` for sudo                  |

main_pc/mini_pc: run `platforms/windows/bootstrap.yml` from an Admin
PowerShell before applying inside WSL.

## Components

`alacritty · claude · clojure · git · google-cloud · hyprland ·
languages · mooncake · moongit · nvim · palette · ssh · terraform · tmux ·
usql · zsh`

Each is self-contained: `index.yml` declares steps, `templates/*.j2` render
into place. Add a component → reference it from a machine's `index.yml`.

## Rules of engagement

- All config flows through dotfiles + mooncake. No drift.
- Templates are Jinja2; pass literal `{{ }}` via `{% verbatim %}`.
- Track work as moongit issues (`mgit`): claim before coding, close when
  merged. Worktrees for non-trivial changes. Never auto-push. See
  [CLAUDE.md](CLAUDE.md).

[MIT](LICENSE)
