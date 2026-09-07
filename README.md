# dotfiles

Personal machine config. Declarative. Reproducible. One source of truth.
**Deploy only via [provision](https://github.com/alehatsman/provision).** Never
`cp`/`ln`/hand-edit managed destinations.

## Bootstrap a fresh machine

From nothing to provisioned. The only step that can't be automated is
putting the generated SSH public key on GitHub — the run prints it and
tells you when.

```sh
git clone https://github.com/alehatsman/dotfiles ~/dotfiles && cd ~/dotfiles
export PATH="$HOME/.local/bin:$PATH"      # until components/zsh lands
provision plan ./<machine>.yml            # preview; works before anything exists
provision apply ./<machine>.yml --ask-sudo-pass
```

Every step is idempotent — re-run after fixing anything that fails.

`provision validate ./<machine>.yml` is the cheap check: it parses every
imported file and renders every template without touching the machine, and
every error it reports carries `file:line:col`. `provision plan
--plan-no-probe` does the same and prints the step list. Both run on any
host for any machine, so a mac can check main_pc's config.

Per-platform notes:

- **macOS** — `--ask-sudo-pass` is required (Rosetta, `scutil`, `defaults`
  run as root).
  Homebrew installs itself during the run. First apply is ~30 min plus
  cask downloads.
- **Arch** — `platforms/arch/bootstrap.sh` does the clone + install +
  apply in one shot on first boot.
- **Windows** — run `platforms/windows/bootstrap.yml` from an Admin
  PowerShell first, then the sequence above *inside* WSL.

## Deploy

```sh
just                       # list recipes
just <machine>             # apply  (x1|main_pc|mini_pc|mac|work_mac)
just plan <machine>        # plan, no changes
just ci                    # parse + render all five plans, no system reads
just backup                # snapshot rc files → ~/.dotfiles-backup
just upgrade               # deliberate full system upgrade (never part of apply)
```

Direct: `provision apply ./<machine>.yml` (`plan` to preview). Add
`--ask-sudo-pass` on x1, mac and work_mac; main_pc and mini_pc have
NOPASSWD sudo.

## Layout

```
<machine>.yml      entrypoint: load vars → import machines/<m>/index.yml
machines/<m>/      per-host: index.yml (component set), vars.yml
components/<c>/    unit of config: index.yml + templates/*.j2
platforms/<p>/     OS-specific: arch, macos, windows
shared/            variables.yml, bootstrap.yml
scripts/           install_mooncake.sh, test-docker.sh
docs/              nvim, tmux, keybindings, windows-ssh-setup
justfile           dev surface (`just`); replaces the old tasks.yml
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

- All config flows through dotfiles + provision. No drift.
- Templates are Jinja2; pass literal `{{ }}` via `{% verbatim %}`.
- Track work as moongit issues (`mgit`): claim before coding, close when
  merged. Worktrees for non-trivial changes. Never auto-push. See
  [CLAUDE.md](CLAUDE.md).

[MIT](LICENSE)
