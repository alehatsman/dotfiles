# dotfiles

Personal machine config. Declarative. Reproducible. One source of truth.
**Deploy only via [mooncake](components/mooncake).** Never `cp`/`ln`/hand-edit
managed destinations.

## Deploy

```sh
mooncake task                 # list tasks
mooncake task <machine>       # apply  (x1|main_pc|mini_pc|mac)
mooncake task <machine> -p    # plan, no changes
mooncake task <machine> -K    # apply, prompt for sudo (x1, mac)
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

main_pc/mini_pc: run `platforms/windows/bootstrap.yml` from an Admin
PowerShell before applying inside WSL.

## Components

`alacritty · claude · clojure · dex · git · google-cloud · hyprland ·
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
