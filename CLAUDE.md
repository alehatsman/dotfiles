# Dotfiles — Claude Instructions

## Deployment: always use mooncake, never manual copies

This repo is provisioned by [mooncake](https://github.com/alehatsman/mooncake). The user
is actively developing mooncake and wants every deployment to flow through it
so edge cases surface and get fixed.

**Never** `cp`, `ln`, or hand-write files into `~/.config/...` (or any other
destination managed by `main.yml`). **Always** deploy via mooncake — even for
a one-line CSS tweak or a quick test.

### How to deploy

From the repo root:

```
./scripts/run.sh --tags <tag>          # deploy a specific slice
./scripts/run.sh --tags <tag> --dry-run  # preview without applying
./scripts/run.sh                       # full provision (prompts for sudo via -K)
```

Tags are defined per-step in `*/main.yml`. Examples:

| Change                          | Tag to use         |
| ------------------------------- | ------------------ |
| `hyprland/templates/wofi-*.j2`  | `wofi`             |
| `hyprland/templates/waybar-*.j2`| `waybar`           |
| `hyprland/templates/alacritty*` | `alacritty`        |
| `hyprland/templates/hypr*`      | `hyprland`         |
| `hyprland/templates/dunstrc.j2` | `dunst`            |
| `hyprland/templates/nwg-dock*`  | `dock`             |
| anything under `nvim/`          | check `nvim/main.yml` |
| anything under `zsh/`           | check `zsh/main.yml`  |

If you don't know the tag, `grep "tags:" <area>/main.yml` to find it, or just
run the area-level tag (e.g. `hyprland`).

### Workflow

1. Edit the template (`*.j2`) or `main.yml` in the repo.
2. Run `./scripts/run.sh --tags <tag> --dry-run` first to see what mooncake will do.
3. Run `./scripts/run.sh --tags <tag>` to apply.
4. If mooncake fails or behaves unexpectedly, **stop and report it** — that's
   the whole point. Do not fall back to `cp` to "just get it deployed."

### When mooncake breaks

If a deployment fails, surface the error verbatim and the command that
triggered it. The user wants to fix mooncake, not work around it.
