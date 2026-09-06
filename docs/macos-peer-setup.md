# Make a Mac reachable as a fleet peer

Companion to `docs/windows-ssh-setup.md`. Most of this is automated by
`components/fleet-peer/index.yml`; this file covers the parts that cannot be,
and the order they have to happen in.

Applies to any macOS box with `fleet_peer_enabled: "true"` in
`machines/<m>/vars.yml`. Currently: `mac`.

## What the apply does for you

```
mooncake apply -c ./mac.yml -K -t fleet-peer
```

1. `~/.ssh` at `0700`, `~/.ssh/authorized_keys` at `0600`, rendered from
   `fleet_ssh_keys` in `shared/variables.yml`.
2. `systemsetup -setremotelogin on` — inbound sshd on `:22`.
3. `mooncake agentd bootstrap --port 7878` — installs and starts the launchd
   plist at `/Library/LaunchDaemons/com.mooncake.agentd.plist`.
4. Asserts both ports are actually listening.

`-K` is required. Steps 2 and 3 are `as_user: root`.

## Prerequisite that cannot be automated: Full Disk Access

`systemsetup -setremotelogin on` needs the **calling terminal** to hold Full
Disk Access. Without it the command exits 0 and does nothing — Remote Login
stays off and there is no error to catch. This is why the component asserts on
`nc -z 127.0.0.1 22` afterwards instead of trusting the exit code.

Grant it before applying:

System Settings → Privacy & Security → Full Disk Access → add your terminal
(Alacritty, Terminal.app, iTerm — whichever runs `mooncake`), then **fully quit
and reopen it**. The permission is read at process start; a running terminal
does not pick it up.

Verify:

```sh
sudo systemsetup -getremotelogin   # → Remote Login: On
```

## Pair the peer with a controller

`agentd bootstrap` prints a bearer token and a ready-made `fleet pair` line.
`peers.toml` lives on the **controller**, not on the peer — run the printed
command there (typically main_pc):

```sh
mooncake fleet pair mac --addr 192.168.1.180:7878 --token <token>
mooncake fleet status
```

Do not use `mooncake fleet bootstrap alehatsman@192.168.1.180` for this. That
form SFTPs the *controller's* binary onto this Mac and errors on version
mismatch — bootstrapping from a controller that is behind downgrades the Mac's
mooncake. The component installs from the binary already on the box for exactly
this reason. Keep controllers current with `mooncake task install` instead.

## Adding a machine's key

Public keys are declared in `fleet_ssh_keys` (`shared/variables.yml`), not
edited into `authorized_keys` by hand — the template overwrites that file on
every apply, so a hand-added key disappears on the next run.

```sh
cat ~/.ssh/id_ed25519.pub    # on the machine that needs access
```

Add the line to `fleet_ssh_keys`, commit, and re-apply on every peer.
Revoking is the same edit in reverse: the render is authoritative, so a deleted
entry is gone from the box on the next apply.

**Still missing** (dotfiles#2): `mini_pc` was offline when the list was
collected and `work_mac` was never queried. Neither can reach a fleet-peer
machine until their keys are added.

## Recommended hardening (manual)

macOS ships `PasswordAuthentication yes`. Since every fleet machine
authenticates by key, turn it off — this edits `/etc/ssh/sshd_config`, which
mooncake deliberately does not manage here (clobbering the OS sshd config on a
workstation is a bigger blast radius than this component warrants):

```sh
sudo sed -i '' 's/^#*PasswordAuthentication.*/PasswordAuthentication no/' /etc/ssh/sshd_config
sudo launchctl kickstart -k system/com.openssh.sshd
```

Confirm you can still get in from another machine **before** closing your
existing session.

## Turning it off

```sh
sudo systemsetup -setremotelogin off
sudo launchctl bootout system/com.mooncake.agentd
sudo rm /Library/LaunchDaemons/com.mooncake.agentd.plist
```

Then set `fleet_peer_enabled: "false"` in `machines/mac/vars.yml` so the next
apply does not turn it back on, and drop the peer from the controller's
`peers.toml`.

## Troubleshooting

| Symptom | Cause |
|---|---|
| `setremotelogin` succeeds, `:22` still closed | Terminal lacks Full Disk Access, or was not restarted after granting it |
| Key rejected, right key in `authorized_keys` | Permissions — sshd ignores the file unless it is `0600` and `~/.ssh` is `0700` |
| `agentd bootstrap` refuses on version | Peer and controller disagree; run `mooncake task install` here, do not pass `--upgrade` blindly |
| `fleet status` red, `:22` fine | agentd not running, or `:7878` blocked; check `sudo launchctl print system/com.mooncake.agentd` |
