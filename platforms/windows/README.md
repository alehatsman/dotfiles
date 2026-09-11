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

Fleet peer bootstrap (agentd daemons, `fleet status`) was a feature of the
old provisioning tool and was removed along with it — provision has no fleet
feature. This box is reachable over plain SSH only; see `components/fleet-peer`.
