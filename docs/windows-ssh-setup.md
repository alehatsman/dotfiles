# Enable SSH on the Windows box

All PowerShell commands below must be run as **Administrator**.

## 1. Install OpenSSH Server

```powershell
Add-WindowsCapability -Online -Name OpenSSH.Server~~~~0.0.1.0
```

## 2. Start it and enable autostart

```powershell
Start-Service sshd
Set-Service -Name sshd -StartupType Automatic
```

The installer auto-creates the firewall rule `OpenSSH-Server-In-TCP` for port 22.

## 3. Install Claude's public key

Windows OpenSSH gotcha: if the Windows account is in the **Administrators** group,
sshd ignores `C:\Users\<you>\.ssh\authorized_keys` and reads
`C:\ProgramData\ssh\administrators_authorized_keys` instead. Since admin is
needed to test `bootstrap.yml`, your account is almost certainly an admin —
use the admin path.

Paste this in Admin PowerShell:

```powershell
$key = 'ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIMGss5QZDXkBE9WVH1VZLKG5aXH9edCJWUUASJsBBkNS alehatsman@x1'
$path = "$env:ProgramData\ssh\administrators_authorized_keys"
Add-Content -Path $path -Value $key

# Fix ACL — this file requires Administrators+SYSTEM only or sshd silently refuses it
icacls.exe $path /inheritance:r /grant "Administrators:F" /grant "SYSTEM:F"
```

If the account is **not** in Administrators, use
`C:\Users\<you>\.ssh\authorized_keys` instead and skip the `icacls` step.

## 4. Disable password auth (recommended)

Edit `C:\ProgramData\ssh\sshd_config`:

```
PasswordAuthentication no
PubkeyAuthentication yes
```

Then restart:

```powershell
Restart-Service sshd
```

## 5. Get the LAN IP and send it back

```powershell
Get-NetIPAddress -AddressFamily IPv4 |
  Where-Object { $_.PrefixOrigin -eq 'Dhcp' -or $_.PrefixOrigin -eq 'Manual' } |
  Select-Object IPAddress, InterfaceAlias
```

Reply with:
- the IP (e.g. `192.168.1.42`)
- your Windows username
- confirm `Get-Service sshd` shows `Running`

## When done with the work session

Re-enable lock-down:

```powershell
Stop-Service sshd
Set-Service -Name sshd -StartupType Disabled

# Optional: remove Claude's key
$path = "$env:ProgramData\ssh\administrators_authorized_keys"
(Get-Content $path) | Where-Object { $_ -notmatch 'alehatsman@x1' } | Set-Content $path
```
