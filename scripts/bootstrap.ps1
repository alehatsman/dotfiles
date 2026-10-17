# Bootstrap a Windows host: get git, ~/dotfiles and provision.exe onto a
# machine that has none of them, then hand off to ./<machine>.host.yml.
# The Windows twin of bootstrap.sh.
#
# Only what no plan can do lives here: a plan needs provision.exe to run and
# a checkout to read, and an apply must not swap out the binary running it
# (components/provision). Everything else -- packages, ~/projects, PATH,
# gitconfig, WSL, power, firewall -- is declared under platforms/windows/host/.
# Git and WinLibs are installed here only when missing; the plan declares
# both, so it owns them from the first apply on.
#
#   .\scripts\bootstrap.ps1                          install, print next step
#   .\scripts\bootstrap.ps1 -Machine mini_pc -Plan   install, then live plan
#   .\scripts\bootstrap.ps1 -Machine mini_pc         install, then apply (Admin)
#
# On a fresh box, with no checkout yet:
#   & ([scriptblock]::Create((irm https://raw.githubusercontent.com/alehatsman/dotfiles/main/scripts/bootstrap.ps1))) -Machine <m> -Plan
#
# Env:
#   PROVISION_REF   git ref to build (default: provision_ref in
#                   shared/variables.yml, which is `main`)
#   PREFIX          install dir (default ~\.local\bin)
#   FORCE           set to 1 to rebuild even if already current
#
# Re-running is cheap: it skips the build when the installed commit already
# matches the remote ref, and every other step checks before it acts.
[CmdletBinding()]
param(
    [string]$Machine,
    [switch]$Plan
)
$ErrorActionPreference = 'Stop'

function Say($msg) { Write-Host "==> $msg" }
function Die($msg) { Write-Host "error: $msg" -ForegroundColor Red; exit 1 }

# PowerShell 5.1 does not stop on a native command's non-zero exit, so every
# call that matters goes through this.
function Invoke-Checked {
    param([string]$What, [scriptblock]$Block)
    & $Block
    if ($LASTEXITCODE -ne 0) { Die "$What failed (exit $LASTEXITCODE)" }
}

# winget and rustup edit PATH in the registry; this process does not see it
# until it re-reads.
function Update-Path {
    $env:Path = [Environment]::GetEnvironmentVariable('Path', 'Machine') + ';' +
                [Environment]::GetEnvironmentVariable('Path', 'User')
}

$DotfilesRepo  = 'https://github.com/alehatsman/dotfiles'
$ProvisionRepo = 'https://github.com/alehatsman/provision'
$Prefix = if ($env:PREFIX) { $env:PREFIX } else { Join-Path $HOME '.local\bin' }
# Same stamp path as bootstrap.sh: the binary cannot say which commit it is
# (Cargo.toml has read 0.9.1 across many), so the stamp is the record.
$Stamp = Join-Path $HOME '.local\state\provision\installed-ref'
# windows-gnu, matching provision's own release build (D1): -msvc needs the
# Visual Studio Build Tools, a multi-GB install for one 3 MB binary.
$RustHost = 'x86_64-pc-windows-gnu'

# --- Git ---------------------------------------------------------------------
# Installed here, not left to the plan, because nothing else can happen
# without it.
if (-not (Get-Command winget -ErrorAction SilentlyContinue)) {
    Die 'winget not found -- install "App Installer" from the Microsoft Store'
}
if (-not (Get-Command git -ErrorAction SilentlyContinue)) {
    Say 'git not found -- installing Git.Git via winget'
    Invoke-Checked 'winget install Git.Git' {
        winget install --id Git.Git -e --silent --accept-source-agreements --accept-package-agreements
    }
    Update-Path
    if (-not (Get-Command git -ErrorAction SilentlyContinue)) { Die 'git still not on PATH after install' }
}

# --- Checkout ----------------------------------------------------------------
# Run from a checkout (or a worktree of one), use that checkout. Run piped
# from the web, there is none: use ~/dotfiles, cloning it if absent.
$repoRoot = $null
if ($PSScriptRoot) {
    $candidate = Split-Path -Parent $PSScriptRoot
    if (Test-Path (Join-Path $candidate 'shared\variables.yml')) { $repoRoot = $candidate }
}
if (-not $repoRoot) {
    $repoRoot = Join-Path $HOME 'dotfiles'
    if (-not (Test-Path $repoRoot)) {
        Say "cloning $DotfilesRepo to $repoRoot"
        Invoke-Checked 'git clone dotfiles' { git clone -q $DotfilesRepo $repoRoot }
    }
}

# --- provision ref -----------------------------------------------------------
# Read the same line bootstrap.sh reads, so the two platforms build one ref.
$pinned = Select-String -Path (Join-Path $repoRoot 'shared\variables.yml') -Pattern '^provision_ref:\s*"([^"]+)"' |
    Select-Object -First 1 | ForEach-Object { $_.Matches[0].Groups[1].Value }
if (-not $pinned) { Die "no provision_ref in $repoRoot\shared\variables.yml" }
$ref = if ($env:PROVISION_REF) { $env:PROVISION_REF } else { $pinned }

$wantSha = (git ls-remote $ProvisionRepo $ref | Select-Object -First 1) -split '\s+' | Select-Object -First 1
if (-not $wantSha) { Die "cannot resolve $ref on $ProvisionRepo (offline?)" }
$short = $wantSha.Substring(0, 12)

$exe = Join-Path $Prefix 'provision.exe'
$stamped = if (Test-Path $Stamp) { (Get-Content $Stamp -Raw).Trim() } else { '' }
$needInstall = $true
if ($env:FORCE -eq '1') {
    Say 'FORCE=1 -- rebuilding'
} elseif ((Test-Path $exe) -and $stamped -eq $wantSha) {
    Say "provision at $short already installed at $exe"
    $needInstall = $false
} elseif ($stamped) {
    Say "provision at $($stamped.Substring(0, 12)) installed, $ref is now $short -- rebuilding"
} else {
    Say "provision not installed (or unstamped) -- installing $ref ($short)"
}

if ($needInstall) {
    # --- Rust ----------------------------------------------------------------
    # rustup only if absent -- never reconfigure someone's existing toolchain
    # as a side effect. The toolchain is installed by explicit name below, so
    # the default host is never touched either.
    if (-not (Get-Command rustup -ErrorAction SilentlyContinue)) {
        $cargoBin = Join-Path $HOME '.cargo\bin'
        if (-not (Test-Path (Join-Path $cargoBin 'rustup.exe'))) {
            Say "no rustup -- installing it (host $RustHost, no default toolchain)"
            $init = Join-Path ([IO.Path]::GetTempPath()) 'rustup-init.exe'
            Invoke-WebRequest -UseBasicParsing -Uri 'https://win.rustup.rs/x86_64' -OutFile $init
            Invoke-Checked 'rustup-init' {
                & $init -y --default-host $RustHost --default-toolchain none --profile minimal --no-modify-path
            }
            Remove-Item $init -Force
        }
        $env:Path = "$cargoBin;$env:Path"
    }

    # windows-gnu links import libraries through MinGW's dlltool (windows-sys
    # fails with "error calling dlltool 'dlltool.exe': program not found"),
    # and rustup does not ship one. WinLibs is MinGW-w64 as a winget package;
    # provision's release build gets the same tool from Debian's mingw-w64.
    if (-not (Get-Command dlltool -ErrorAction SilentlyContinue)) {
        Say 'no dlltool -- installing MinGW-w64 (BrechtSanders.WinLibs.POSIX.UCRT) via winget'
        Invoke-Checked 'winget install WinLibs' {
            winget install --id BrechtSanders.WinLibs.POSIX.UCRT -e --silent --accept-source-agreements --accept-package-agreements
        }
        Update-Path
        $env:Path = "$(Join-Path $HOME '.cargo\bin');$env:Path"
        if (-not (Get-Command dlltool -ErrorAction SilentlyContinue)) { Die 'dlltool still not on PATH after installing WinLibs' }
    }

    # Build in a temp clone at the resolved commit: the thing built is exactly
    # the thing checked above, even if the ref moves mid-run, and no source
    # tree is left behind to go stale.
    $tmp = Join-Path ([IO.Path]::GetTempPath()) ("provision-" + [guid]::NewGuid().ToString('N').Substring(0, 8))
    try {
        Say "fetching $ProvisionRepo at $short"
        Invoke-Checked 'git init' { git init -q $tmp }
        Invoke-Checked 'git remote add' { git -C $tmp remote add origin $ProvisionRepo }
        Invoke-Checked "git fetch $short" { git -C $tmp fetch -q --depth 1 origin $wantSha }
        Invoke-Checked 'git checkout' { git -C $tmp checkout -q FETCH_HEAD }

        # provision pins its compiler in rust-toolchain.toml. Naming the
        # channel with an explicit host gets that compiler for windows-gnu
        # whatever this machine's default host is.
        $channel = Select-String -Path (Join-Path $tmp 'rust-toolchain.toml') -Pattern '^channel\s*=\s*"([^"]+)"' |
            Select-Object -First 1 | ForEach-Object { $_.Matches[0].Groups[1].Value }
        if (-not $channel) { Die 'no channel in provision''s rust-toolchain.toml' }
        $toolchain = "$channel-$RustHost"
        Say "toolchain $toolchain"
        Invoke-Checked "rustup toolchain install $toolchain" {
            rustup toolchain install $toolchain --profile minimal --no-self-update
        }

        Say 'building (this takes a few minutes)'
        Push-Location $tmp
        try {
            Invoke-Checked 'cargo build' { cargo "+$toolchain" build --release --locked }
        } finally { Pop-Location }

        $built = Join-Path $tmp 'target\release\provision.exe'
        if (-not (Test-Path $built)) { Die "expected binary at $built, not found" }

        New-Item -ItemType Directory -Force $Prefix | Out-Null
        # Temp name then move: a running provision.exe cannot be overwritten in
        # place on Windows, but it can be renamed away first.
        $new = Join-Path $Prefix '.provision.new.exe'
        Copy-Item $built $new -Force
        if (Test-Path $exe) {
            $old = Join-Path $Prefix '.provision.old.exe'
            Remove-Item $old -Force -ErrorAction SilentlyContinue
            Move-Item $exe $old -Force
        }
        Move-Item $new $exe -Force
        # Stamp AFTER the binary lands, so a failed install never claims success.
        New-Item -ItemType Directory -Force (Split-Path -Parent $Stamp) | Out-Null
        Set-Content -Path $Stamp -Value $wantSha -Encoding ascii
        Say "installed $exe at $short"
    } finally {
        Remove-Item $tmp -Recurse -Force -ErrorAction SilentlyContinue
    }
}

# This process only. The persistent user PATH entry is declared in
# platforms/windows/host/home.yml.
if (($env:Path -split ';') -notcontains $Prefix) { $env:Path = "$Prefix;$env:Path" }

Invoke-Checked 'provision --version' { & $exe --version }

if (-not $Machine) {
    Write-Host @"

Next (from $repoRoot):
    provision plan  .\<machine>.host.yml
    provision apply .\<machine>.host.yml   # Administrator
"@
    exit 0
}

$entry = "$Machine.host.yml"
if (-not (Test-Path (Join-Path $repoRoot $entry))) { Die "no such host plan: $repoRoot\$entry" }

Push-Location $repoRoot
try {
    if ($Plan) {
        # Probes the host, changes nothing. The probes read state any user
        # can read, so plan does not demand elevation.
        Say "planning $entry"
        & $exe plan ".\$entry"
    } else {
        # Elevation on Windows is per-process (UAC): provision refuses `sudo:`
        # there, so the shell itself must already be Administrator.
        $principal = New-Object Security.Principal.WindowsPrincipal([Security.Principal.WindowsIdentity]::GetCurrent())
        if (-not $principal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
            Die 'apply needs an Administrator PowerShell (or pass -Plan for a dry run)'
        }
        Say "applying $entry"
        & $exe apply ".\$entry"
    }
    exit $LASTEXITCODE
} finally { Pop-Location }
