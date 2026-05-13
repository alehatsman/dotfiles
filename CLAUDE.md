# Dotfiles — Claude Instructions

## Deployment: always use mooncake, never manual copies

This repo is provisioned by [mooncake](https://github.com/alehatsman/mooncake). The user
is actively developing mooncake and wants every deployment to flow through it
so edge cases surface and get fixed.

**Never** `cp`, `ln`, or hand-write files into `~/.config/...` (or any other
destination managed by an entry). **Always** deploy via mooncake — even for
a one-line CSS tweak or a quick test.

## Repo shape (per-machine entries)

There is no monolithic `main.yml`. Each machine has its own entry under
`entries/` and a sibling vars file under `vars/`:

| Machine   | Entry                  | Vars                | Notes                                       |
| --------- | ---------------------- | ------------------- | ------------------------------------------- |
| x1        | `entries/x1.yml`       | `vars/x1.yml`       | Arch laptop, Hyprland                       |
| main_pc   | `entries/main_pc.yml`  | `vars/main_pc.yml`  | Windows host (run `bootstrap.yml` first), then WSL Ubuntu |
| mini_pc   | `entries/mini_pc.yml`  | `vars/mini_pc.yml`  | Same shape as main_pc                       |
| mac       | `entries/mac.yml`      | `vars/mac.yml`      | macOS                                       |

Each entry imports `common.yml` (the cross-machine baseline: claude, git,
languages, fzf, zsh, tmux, nvim, packages routing) plus its own
platform-specific bits.

## How to deploy

```
./scripts/run.sh --machine x1              # full provision on x1
./scripts/run.sh --machine x1 --plan       # preview only (mooncake plan)
./scripts/run.sh --machine x1 --tags zsh   # only the zsh slice
```

Or via make:

```
make x1        # full provision
make x1-plan   # preview only
make help      # list all targets
```

## Windows two-step

Windows host setup (firewall, scheduled task, WSL install) lives in
`platforms/windows/bootstrap.yml`. Run that from an Administrator
PowerShell once per machine:

```
mooncake.exe apply -c platforms\windows\bootstrap.yml -v variables.yml -v vars\main_pc.yml
```

Then proceed with the WSL-side entry as above.

## Tags

Tags filter which steps run. Apply tags propagate from `import` steps down
to all included steps (mooncake's expansion handles that). Common ones:

| Change                          | Tag to use         |
| ------------------------------- | ------------------ |
| `hyprland/templates/wofi-*.j2`  | `wofi`             |
| `hyprland/templates/waybar-*.j2`| `waybar`           |
| `hyprland/templates/hypr*`      | `hyprland`         |
| `hyprland/templates/dunstrc.j2` | `dunst`            |
| `hyprland/templates/nwg-dock*`  | `dock`             |
| anything under `nvim/`          | check `nvim/main.yml`  |
| anything under `zsh/`           | check `zsh/main.yml`   |
| WSL-specific provisioning       | `wsl`              |

`grep "tags:" <area>/main.yml` finds local tags. The Arch-system block
under `platforms/arch/` uses `arch`/`system`/`packages`.

## Workflow

1. Edit the template (`*.j2`) or YAML in the repo.
2. `./scripts/run.sh --machine <m> --plan --tags <tag>` first.
3. `./scripts/run.sh --machine <m> --tags <tag>` to apply.
4. If mooncake fails or behaves unexpectedly, **stop and report it** —
   that's the whole point. Do not fall back to `cp` to "just get it
   deployed."

## When mooncake breaks

If a deployment fails, surface the error verbatim and the command that
triggered it. The user wants to fix mooncake, not work around it.
