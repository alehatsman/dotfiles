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

Steps 2 and 3 are `as_user: root`. `-K` was required until passwordless sudo
was provisioned on darwin (`shared/bootstrap.yml`, `/etc/sudoers.d/<user>-nopasswd`);
on a machine that has been bootstrapped since, it is harmless but unnecessary.
Keep it for a first-run box whose sudoers drop-in is not in place yet.

## Prerequisite that cannot be automated: Full Disk Access

`systemsetup -setremotelogin on` needs the **calling terminal** to hold Full
Disk Access. On macOS 15 it fails loudly without it:

```
setremotelogin: Turning Remote Login on or off requires Full Disk Access privileges.
command failed with exit code 1
```

Older releases exited 0 and did nothing, leaving Remote Login off with no error
to catch. The component's `nc -z 127.0.0.1 22` assert was added for that silent
case and is worth keeping — it is the honest end-state check either way — but on
current macOS the shell step fails first.

Grant it before applying:

System Settings → Privacy & Security → Full Disk Access → add your terminal
(Alacritty, Terminal.app, iTerm — whichever runs `mooncake`), then **fully quit
and reopen it**. The permission is read at process start; a running terminal
does not pick it up.

**Restarting the terminal is not enough on its own if you run under tmux.** TCC
grants attach to the responsible process, and a tmux server started before the
grant keeps the old context — every `mooncake` invocation inside it inherits the
denial no matter how many times the terminal is reopened. Kill the server too:

```sh
tmux kill-server    # ends any session running inside it, including this one
```

Confirm the new process chain actually holds the grant before re-applying — this
read succeeds only with Full Disk Access:

```sh
sqlite3 "/Library/Application Support/com.apple.TCC/TCC.db" "select count(*) from access;"
```

### Or skip TCC entirely

Flipping the GUI toggle does the same thing with no Full Disk Access involved:

System Settings → General → Sharing → **Remote Login** → on

The component's `unless_command` gate (`systemsetup -getremotelogin | grep -q
'On$'`) then skips the step cleanly on the next apply, leaving only the agentd
bootstrap to run. Usually the faster path.

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
| `setremotelogin: ... requires Full Disk Access privileges`, exit 1 | Terminal lacks Full Disk Access (macOS 15+ fails loudly) |
| `setremotelogin` succeeds, `:22` still closed | Older macOS silent no-op; or FDA granted but the tmux server predates the grant |
| Key rejected, right key in `authorized_keys` | Permissions — sshd ignores the file unless it is `0600` and `~/.ssh` is `0700` |
| `agentd bootstrap` refuses on version | Peer and controller disagree; run `mooncake task install` here, do not pass `--upgrade` blindly |
| `fleet status` red, `:22` fine | agentd not running, or `:7878` blocked; check `sudo launchctl print system/com.mooncake.agentd` |
| agentd installs, then `never reachable after 10s` | mooncake predating alehatsman/mooncake#50 — `--system` used the Linux `/run/mooncake`, which macOS cannot create. Read `/var/log/mooncake-agentd.log`; upgrade the peer's binary |
| `Permission denied (publickey)` with the right key | Wrong username. The account is `alehatsman`, not `aleh` — `ssh alehatsman@<host>` |
