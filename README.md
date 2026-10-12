# dotfiles

Personal machine config. Declarative. Reproducible. One source of truth.
**Deploy only via [provision](https://github.com/alehatsman/provision).** Never
`cp`/`ln`/hand-edit managed destinations.

![provision apply ./main_pc.yml on main_pc](docs/demo.gif)

Recorded live on main_pc: a full `provision apply ./main_pc.yml` run,
every component. Recorded with [asciinema](https://asciinema.org),
converted to gif with [agg](https://github.com/asciinema/agg) — both
installed by the [asciinema](components/asciinema) component.

## Bootstrap a fresh machine

From nothing to provisioned. `provision` is not packaged and has no
releases, so step one builds it from source at the ref this repo tracks
(`provision_ref` in `shared/variables.yml`). See [docs/bootstrap.md](docs/bootstrap.md).

The only step that can't be automated is putting the generated SSH public
key on GitHub — the run prints it and tells you when.

```sh
git clone https://github.com/alehatsman/dotfiles ~/dotfiles && cd ~/dotfiles
./scripts/bootstrap.sh                    # builds provision, installs the pre-push hook
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

- **macOS** — Homebrew installs itself during the run. First apply is
  ~30 min plus cask downloads.
- **Arch** — `platforms/arch/bootstrap.sh` does the clone + apply in one
  shot on first boot; run `scripts/bootstrap.sh` first to get `provision`.
- **Windows** — run `platforms/windows/bootstrap.yml` from an Admin
  PowerShell first, then the sequence above *inside* WSL.

## Deploy

```sh
just                       # list recipes
just <machine>             # apply  (x1|main_pc|mini_pc|mac|work_mac|pixel)
just plan <machine>        # plan, no changes
just ci                    # validate + render all six machine plans, no system reads
just fleet-status          # where every fleet box is, and at what commit
just fleet-sync            # pull + apply on every reachable fleet box
just hooks                 # install the pre-push validation hook
just backup                # snapshot rc files → ~/.dotfiles-backup
just upgrade               # deliberate full system upgrade (never part of apply)
```

Direct: `provision apply ./<machine>.yml` (`plan` to preview).
`--ask-sudo-pass` is only for a machine that has never been applied to:
`shared/bootstrap.yml` installs a NOPASSWD sudoers drop-in on every host,
so once that has landed there is no password to ask for.

Each `just <machine>` recipe appends a JSON run log to
`~/.local/state/provision/<machine>.jsonl` while still printing to the
terminal.

## Layout

```
<machine>.yml      entrypoint: load vars → import machines/<m>/index.yml
machines/<m>/      per-host: index.yml (component set), vars.yml
components/<c>/    unit of config: index.yml + templates/*.j2
platforms/<p>/     OS-specific: arch, macos, windows
shared/            variables.yml, bootstrap.yml, guard.yml, core.yml, shell.yml
scripts/           bootstrap.sh, validate.sh, fleet.sh, hooks/pre-push, test-podman.sh
docs/              bootstrap, fleet-structure, nvim, tmux, keybindings, windows-ssh-setup
justfile           dev surface (`just`)
```

## Machines

| host    | platform                | notes                          |
|---------|-------------------------|--------------------------------|
| x1      | Arch laptop, Hyprland   | Hyprland/thermal tuning        |
| main_pc | Windows 11 + WSL2 Ubuntu| Windows host bootstrap first   |
| mini_pc | WSL                     | Windows host bootstrap first   |
| mac     | macOS                   | Homebrew bootstraps itself     |
| work_mac| macOS (NVIDIA work box) | Homebrew bootstraps itself     |
| pixel   | Pixel 9a, GrapheneOS    | applied from the Mac over adb; manual steps in `machines/pixel/index.yml` |

main_pc/mini_pc: run `platforms/windows/bootstrap.yml` from an Admin
PowerShell before applying inside WSL.

## Components

`alacritty · asciinema · claude · cli · codefort · codex · fleet-peer ·
gdrive-mirror · git · hyprland · languages · nvim · palette · provision ·
ssh · teleport · termux · tmux · usql · zsh`

Each is self-contained: `index.yml` declares steps, `templates/*.j2` render
into place.

The set every machine gets lives in `shared/core.yml` (palette, claude,
codex, git, cli, languages) and `shared/shell.yml` (zsh, tmux, nvim) — add a
component there to give it to the whole fleet, or reference it from a single
machine's `index.yml` to give it to one.

## Rules of engagement

- All config flows through dotfiles + provision. No drift. That includes
  removals: an app nobody declared gets declared or goes `state: absent`.
- Templates are Jinja2; pass literal `{{ }}` via `{% verbatim %}`.
- Validation is local, never GitHub Actions. `scripts/hooks/pre-push`
  refuses a push whose machine plans do not render; `just ci` runs the same
  check by hand. Bypass with `--no-verify` and own it.
- Track work as GitHub issues on `alehatsman/dotfiles`. Worktrees for
  non-trivial changes. Never auto-push. See [CLAUDE.md](CLAUDE.md).

[MIT](LICENSE)
