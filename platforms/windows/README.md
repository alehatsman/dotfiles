# Windows host bootstrap

Run from an **Administrator PowerShell** on a fresh Windows 11 box:

```powershell
provision.exe apply platforms\windows\bootstrap.yml --vars-file machines\<machine>\vars.yml
```

Elevation is process-wide on Windows (UAC), not per-step — there is no
`sudo:` in `bootstrap.yml`, so the shell you launch it from must already be
elevated.

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
operator documentation, not machine state, so it lives here instead
(docs/migration.md §3.9).

4. Add your SSH public key to `~/.ssh/authorized_keys` (WSL side).
5. `wsl --shutdown`, then verify: `ssh <this-pc-ip> -p <wsl_ssh_port>`.
6. From your controller machine (e.g. x1), bootstrap **both** agentd
   daemons — one inside the WSL distro, one on the Windows host. Each
   command SCPs the right mooncake binary, installs the OS-native
   autostart (systemd unit on Linux, Task Scheduler entry on Windows),
   opens the firewall, and writes the peer entry to `peers.toml`.

   ```sh
   # WSL (Linux) peer — through WSL's OpenSSH on :<wsl_ssh_port>
   mooncake fleet bootstrap <user>@<this-pc-ip> \
       --port <wsl_ssh_port> --agentd-port <wsl_agentd_port> \
       --name <machine> --tag <machine> --upgrade

   # Windows-host peer — through Windows OpenSSH on :22
   mooncake fleet bootstrap <user>@<this-pc-ip> \
       --port 22 --agentd-port <windows_agentd_port> \
       --name <machine>-win --tag windows --upgrade
   ```

7. Confirm both peers green:

   ```sh
   mooncake fleet status
   ```

   Expect `2/2 accessible`: `<machine>` (linux) + `<machine>-win` (windows).

The fleet is mooncake's, and stays mooncake's — provision has no fleet
feature and is not getting one. The port values come from the machine's
`machines/<m>/vars.yml`.
