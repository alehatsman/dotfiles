# bootstrap.ps1 — Run once as Administrator on a fresh Windows 11 machine.
# Sets up WSL2 + Ubuntu, firewall, and Task Scheduler autostart.
# After this script: reboot, finish Ubuntu first-run setup, then run mooncake.

#Requires -RunAsAdministrator
Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

function Log { param($msg) Write-Host "[INFO] $msg" -ForegroundColor Cyan }

# ── 1. Enable WSL and install Ubuntu ──────────────────────────────────────────
wsl --set-default-version 2
$distros = wsl --list --quiet 2>$null
if ($distros -match "Ubuntu-24.04") {
    Log "Ubuntu-24.04 already installed — skipping"
} else {
    Log "Installing Ubuntu-24.04..."
    wsl --install -d Ubuntu-24.04
}

# ── 2. Write .wslconfig (mirrored networking) ─────────────────────────────────
$wslConfig = @"
[wsl2]
networkingMode=mirrored
dnsTunneling=true
firewall=true

[experimental]
autoMemoryReclaim=gradual
"@

$wslConfigPath = "$env:USERPROFILE\.wslconfig"
Log "Writing $wslConfigPath..."
Set-Content -Path $wslConfigPath -Value $wslConfig -Encoding UTF8

# ── 3. Firewall rule for WSL SSH ──────────────────────────────────────────────
$ruleName = "WSL2 SSH"
if (-not (Get-NetFirewallRule -DisplayName $ruleName -ErrorAction SilentlyContinue)) {
    Log "Adding firewall rule for port 2222..."
    New-NetFirewallRule `
        -DisplayName $ruleName `
        -Direction Inbound `
        -Protocol TCP `
        -LocalPort 2222 `
        -Action Allow `
        -Profile Domain,Private | Out-Null
} else {
    Log "Firewall rule '$ruleName' already exists"
}

# ── 4. Task Scheduler — start WSL SSH on system boot ─────────────────────────
$taskName = "WSL2-SSH-Autostart"
if (-not (Get-ScheduledTask -TaskName $taskName -ErrorAction SilentlyContinue)) {
    Log "Registering scheduled task '$taskName'..."
    $action = New-ScheduledTaskAction `
        -Execute "C:\Windows\System32\wsl.exe" `
        -Argument "--exec sudo service ssh start"
    $trigger = New-ScheduledTaskTrigger -AtStartup
    $principal = New-ScheduledTaskPrincipal `
        -UserId "SYSTEM" `
        -LogonType ServiceAccount `
        -RunLevel Highest
    $settings = New-ScheduledTaskSettingsSet `
        -ExecutionTimeLimit (New-TimeSpan -Minutes 2) `
        -RestartCount 3 `
        -RestartInterval (New-TimeSpan -Minutes 1)
    Register-ScheduledTask `
        -TaskName $taskName `
        -Action $action `
        -Trigger $trigger `
        -Principal $principal `
        -Settings $settings `
        -Force | Out-Null
} else {
    Log "Scheduled task '$taskName' already exists"
}

# ── 5. Next steps ─────────────────────────────────────────────────────────────
Write-Host ""
Write-Host "Bootstrap complete. Next steps:" -ForegroundColor Green
Write-Host "  1. Reboot the machine"
Write-Host "  2. Finish Ubuntu first-run setup (set username + password)"
Write-Host "  3. Inside WSL, run:"
Write-Host "       git clone https://github.com/alehatsman/dotfiles ~/dotfiles"
Write-Host "       cd ~/dotfiles && bash scripts/install_mooncake.sh"
Write-Host "       mooncake run -c main.yml -v personal_variables.yml"
Write-Host "  4. Add your SSH public key to ~/.ssh/authorized_keys"
Write-Host "  5. Run 'wsl --shutdown' then verify with: ssh <this-pc-ip> -p 2222"
