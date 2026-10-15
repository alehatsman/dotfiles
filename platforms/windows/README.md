# Windows host bootstrap

Two layers on every Windows box:

| Side | Plan | Run from |
|---|---|---|
| Host | `platforms/windows/bootstrap.yml` + `machines/<m>/vars.yml` | Windows, `provision.exe` |
| WSL guest | `./<m>.yml` | inside WSL, `provision` |

## Fresh box

From an **Administrator PowerShell** (winget must exist — "App Installer"):

```powershell
& ([scriptblock]::Create((irm https://raw.githubusercontent.com/alehatsman/dotfiles/main/scripts/bootstrap.ps1))) -Machine <machine>
```

`scripts/bootstrap.ps1` does only what no plan can: installs Git (winget),
clones `~/dotfiles`, creates `~/projects`, builds `provision.exe` from
`provision_ref` into `~\.local\bin` (rustup with the `x86_64-pc-windows-gnu`
host, plus MinGW-w64 from winget for `dlltool`), then applies the host plan.
Everything after that is declared in `bootstrap.yml`.

**Smart App Control must be off.** It blocks every unsigned executable —
cargo's build scripts first, and `provision.exe` itself after that — with
`An Application Control policy has blocked this file. (os error 4551)`.

Elevation is process-wide on Windows (UAC), not per-step — there is no
`sudo:` in `bootstrap.yml`, so the shell you launch it from must already be
elevated. `bootstrap.ps1` refuses to apply from a non-elevated shell.

## Day to day

```powershell
cd ~\dotfiles
.\scripts\bootstrap.ps1 -Machine <machine> -Plan   # live plan: probes the host, changes nothing
.\scripts\bootstrap.ps1 -Machine <machine>         # apply (Administrator)
```

Re-running is cheap: the build is skipped while the installed commit matches
`provision_ref`. Host packages are winget ids in `windows_winget_packages`
(`shared/variables.yml`) plus `windows_winget_packages_extra`
(`machines/<m>/vars.yml`).

## Testing

- **Static, any host:** `scripts/validate.sh` (`just ci`, and the pre-push
  hook) checks the host plan for every machine whose index imports
  `platforms/windows`, with that machine's vars. No probe runs. From WSL
  every plan is checked; from Git Bash on Windows only the host plans are —
  provision judges `sudo:`/`service` against the reading host, so the Linux
  and mac plans are reported as skipped there.
- **Live, on the host:** `-Plan` above. Steps gated with `unless:` report
  `skip` or `would run` from a real probe — that is the drift report. The
  firewall and scheduled-task steps still use the exit-3 shape and always
  read `would run` under plan.

## Next steps after it finishes

1. Reboot the machine — picks up the scheduled tasks and WSL changes cleanly.
2. Finish Ubuntu first-run setup (set username + password).
3. Inside WSL, clone dotfiles and apply the per-machine entry:

   ```sh
   git clone https://github.com/alehatsman/dotfiles ~/dotfiles
   cd ~/dotfiles
   provision apply ./<this-machine>.yml
   ```

This list used to be a `log:` step at the end of `bootstrap.yml`. It is
operator documentation, not machine state, so it lives here instead.

4. Add your SSH public key to `~/.ssh/authorized_keys` (WSL side).
5. `wsl --shutdown`, then verify: `ssh <this-pc-ip> -p <wsl_ssh_port>`.

Fleet peer bootstrap (agentd daemons, `fleet status`) was a feature of the
old provisioning tool and was removed along with it — provision has no fleet
feature. This box is reachable over plain SSH only; see `components/fleet-peer`.
