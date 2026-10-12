# teleport on Linux

Spec for extending `components/teleport` past macOS, so the WSL boxes run
teleportd as declared state instead of as drift.

## Problem

`components/teleport` is darwin-only. Every one of its ten steps carries
`when: os == 'darwin'`, so importing it on a Linux box runs nothing at all —
it does not fail, it silently does nothing.

Meanwhile mainpc **is already running teleportd**, installed by hand:

- `~/.local/bin/teleportd`, version 0.1.0, dated 2026-09-07
- `~/.config/systemd/user/teleportd.service`, hand-written, with a quoted
  `ExecStart="/home/aleh/.local/bin/teleportd"` and `Restart=on-failure`
- data in `~/.local/share/teleport` (config.toml, presets.toml, state.db)
- `tailscale serve` proxying `https://mainpc.tail37c478.ts.net` → `:7337`

It works. Nothing in this repo declares any of it. That is exactly the drift
CLAUDE.md forbids: rebuild mainpc from the repo and teleportd does not come
back, and minipc — same OS, same role — has none of it.

minipc has no teleportd at all: no binary, no unit, no serve config.

## Goal

teleportd on mainpc and minipc as declared state: built, configured,
autostarted, and reachable on the tailnet, converging to the same result as
the two macs already do.

## Scope

In:

- A Linux branch in `components/teleport`: systemd user unit instead of a
  LaunchAgent, XDG data dir instead of `~/Library/Application Support`.
- `components/teleport/templates/teleportd.service.j2`.
- Importing the component on `main_pc` and `mini_pc` with their real tailnet
  hostnames.
- Adopting mainpc's hand-written unit — replaced by the rendered one.

Out:

- **x1.** Owner's call. It is not on the tailnet, so it has no remote access
  path to provide, and it cannot be reached from here to verify. Its config
  is untouched; no import is added.
- **pixel.** An adb target, not a host that runs a daemon.
- Changing the macOS path in any way. The LaunchAgent flow is working on two
  boxes and is not part of this change.
- Headless (logged-out) autostart on macOS. Still the open upstream gap
  (issue #40); unrelated to Linux.

## Interfaces

### Per-OS paths

`teleport_data_dir` becomes computed rather than a fixed macOS value, because
teleportd resolves it from the platform's own convention
(`directories::BaseDirs::data_local_dir`):

| | path |
|---|---|
| darwin | `~/Library/Application Support/teleport` |
| linux | `~/.local/share/teleport` |

The Linux value is not a guess — it is where mainpc's working install already
keeps its state.

It is computed in a `vars:` step, not in `variables.yml`: that file's values
are data and are never rendered, so a `{{ }}` in it would stay seven literal
characters. The component already uses a `vars:` step for `teleport_path` for
exactly this reason.

### Autostart

| | darwin | linux |
|---|---|---|
| mechanism | LaunchAgent | systemd user unit |
| path | `~/Library/LaunchAgents/<label>.plist` | `~/.config/systemd/user/teleportd.service` |
| reload | `launchctl bootout` + `bootstrap` | `systemctl --user daemon-reload` |
| survives logout | no (issue #40) | yes, via linger |

Linger is already handled: `shared/bootstrap.yml` runs `loginctl enable-linger`
on every Linux host, which is what lets a user unit survive logout. The
systemd path is therefore strictly better than the macOS one here, which is
the reverse of the usual direction and worth stating plainly.

The elaborate bootout/port-wait dance in the darwin branch stays darwin-only.
It exists because launchd would otherwise race the old process off `:7337` and
let the new one fall back to an ephemeral port that `tailscale serve` does not
proxy. systemd restarts a unit synchronously, so the Linux branch is a
`daemon-reload` on unit change plus `state: started, enabled: true` — the same
shape `components/codefort` already uses on this exact box.

### Build

The build step loses its `os == 'darwin'` gate. It needs cargo (from
`components/core` → `languages`) and node/npm (from
`platforms/windows/packages.yml`); both WSL boxes have all three. The
commit-stamp idempotence gate is platform-neutral and unchanged.

### Tailscale Serve

Unchanged and ungated — `tailscale serve --bg http://127.0.0.1:7337` is
identical on both platforms. The `unless` already makes it idempotent.

### Tailnet hostnames

Set per machine via the component's existing `props:` block, because
`variables.yml` cannot carry it (documented in that file: the component's own
`vars_file` runs after the machine's and clobbers it — dotfiles#15).

    main_pc → mainpc.tail37c478.ts.net
    mini_pc → minipc.tail37c478.ts.net

Both confirmed against live `tailscale status`.

## Edge cases

- **mainpc's hand-written unit.** Overwritten by the template. Its
  `Restart=on-failure` only covers crashes; the rendered unit uses
  `Restart=always`, matching the intent of the Windows-side keepalive tasks.
  The daemon is bounced once on the apply that adopts it.
- **Port already held.** teleportd falls back to an ephemeral port when
  `:7337` is taken, and `tailscale serve` only ever proxies `:7337` — a silent
  deafness. The darwin branch guards this explicitly; on Linux systemd's
  synchronous restart closes the window, but the verify step below still
  probes the real port rather than trusting the unit's state.
- **First apply, no systemd.** Not reachable here: both WSL boxes already run
  systemd (`/etc/wsl.conf` sets `systemd=true`), and codefort's user units are
  live on mainpc. The platform's own steps handle the fresh-distro case.
- **minipc has no teleportd yet.** First apply builds from source — a cargo
  release build plus a web UI npm build, so it is slow once and stamped after.
- **x1.** Imports nothing; unchanged. Must be reported as out of scope, not
  as working.

## Validation

- `just ci` exits 0; `provision validate` parses for all six machines.
- Step-set diff: the two macs and x1 must be **unchanged** — this must not
  perturb a working macOS path or a box that was excluded.
- Apply on mainpc and minipc: converges, then a second apply reports zero
  changed.
- `systemctl --user is-active teleportd` → `active` on both.
- `curl 127.0.0.1:7337` → HTTP 200 on both.
- `curl https://<box>.tail37c478.ts.net` → HTTP 200 from another box, which
  is the thing actually being asked for: reachable, not merely running.
- work_mac still answers on its own tailnet URL afterwards.
