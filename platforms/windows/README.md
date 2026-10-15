# Windows

Two layers on every Windows box, each with its own root entry:

| Side | Entry | Plans | Run with |
|---|---|---|---|
| Host | `./<m>.host.yml` | `platforms/windows/host/` | `provision.exe`, Administrator PowerShell |
| WSL guest | `./<m>.yml` | `platforms/windows/index.yml` + `packages.yml` | `provision`, inside WSL |

## Host layout

`platforms/windows/host/index.yml` imports, in order:

| File | Owns |
|---|---|
| `guard.yml` | refuse another known machine's plan (`shared/guard.yml` in PowerShell) |
| `packages.yml` | winget: `windows_winget_packages` + `windows_winget_packages_extra` |
| `home.yml` | computer name, `~/projects`, `~/.local/bin` on PATH, `~/.gitconfig` |
| `wsl.yml` | WSL default version, the distro, `~/.wslconfig` |
| `power.yml` | Fast Startup, AC sleep/hibernate |
| `network.yml` | OpenSSH default shell, Windows + Hyper-V firewall rules |
| `tasks.yml` | scheduled tasks keeping WSL and its ports reachable |
| `verify.yml` | provision, git, gh resolve |

Every shell step is gated with an `unless:` probe, so `plan` on the host
reports real drift per step. Host packages are winget **ids**: shared ones
in `shared/variables.yml`, per-machine ones in `machines/<m>/vars.yml`.

What is not in a plan: `provision.exe` and the Rust toolchain that builds it.
An apply must not swap out the binary running it (`components/provision`),
so `scripts/bootstrap.ps1` owns that, as `scripts/bootstrap.sh` does on unix.

## Fresh box

From an **Administrator PowerShell** (winget must exist — "App Installer"):

```powershell
& ([scriptblock]::Create((irm https://raw.githubusercontent.com/alehatsman/dotfiles/main/scripts/bootstrap.ps1))) -Machine <machine>
```

`scripts/bootstrap.ps1` does only what no plan can: installs Git if missing,
clones `~/dotfiles`, builds `provision.exe` from `provision_ref` into
`~\.local\bin` (rustup on the `x86_64-pc-windows-gnu` host, plus WinLibs
from winget for `dlltool` if missing), then applies `./<machine>.host.yml`.
Git and WinLibs are declared in the plan, which owns them from then on.

**Smart App Control must be off.** It blocks every unsigned executable —
cargo's build scripts first, and `provision.exe` itself after that — with
`An Application Control policy has blocked this file. (os error 4551)`.

Elevation is process-wide on Windows (UAC), not per-step — provision refuses
`sudo:` there, so the shell must already be elevated. `bootstrap.ps1`
refuses to apply from a non-elevated shell.

## Day to day

```powershell
cd ~\dotfiles
provision plan  .\<machine>.host.yml               # probes the host, changes nothing
provision apply .\<machine>.host.yml               # Administrator
provision apply .\<machine>.host.yml --tags packages   # just the winget packages
.\scripts\bootstrap.ps1                            # rebuild provision.exe when provision_ref moved
```

## Testing

- **Static, any host:** `scripts/validate.sh` (`just ci`, and the pre-push
  hook) checks every `*.host.yml` alongside the machine entries, and fails if
  a Windows machine has no host entry. No probe runs. From WSL every plan is
  checked; from Git Bash on Windows only the host plans are — provision
  judges `sudo:`/`service` against the reading host, so the Linux and mac
  plans are reported as skipped there.
- **Live, on the host:** `provision plan .\<machine>.host.yml`. Each step's
  `unless:` probe runs, so `skip`/`ok` means declared state holds and
  `would run`/`would change` is drift.

## After the first host apply

1. Reboot — picks up the scheduled tasks and WSL changes cleanly.
2. Finish Ubuntu first-run setup (set username + password).
3. Inside WSL, get provision and apply the per-machine entry:

   ```sh
   git clone https://github.com/alehatsman/dotfiles ~/dotfiles
   cd ~/dotfiles
   ./scripts/bootstrap.sh <this-machine>
   ```

4. Add your SSH public key to `~/.ssh/authorized_keys` (WSL side).
5. `wsl --shutdown`, then verify: `ssh <this-pc-ip> -p <wsl_ssh_port>`.
6. `gh auth login` on the host (a secret — never in the repo).

Fleet peer bootstrap (agentd daemons, `fleet status`) was a feature of the
old provisioning tool and was removed along with it — provision has no fleet
feature. This box is reachable over plain SSH only; see `components/fleet-peer`.
