# Setup Ghostty shaders for Winghostty on Windows.
# Run once after cloning this repo.

$ErrorActionPreference = "Stop"

$RepoDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$WinghosttyDir = "$env:LOCALAPPDATA\winghostty"
$ShadersDir = "$WinghosttyDir\shaders"
$ConfigFile = "$WinghosttyDir\config.ghostty"
$BlackholeDir = "$env:USERPROFILE\ghostty-blackhole"

# Create directories
if (!(Test-Path $WinghosttyDir)) { New-Item -ItemType Directory -Path $WinghosttyDir | Out-Null }
if (!(Test-Path $ShadersDir)) { New-Item -ItemType Directory -Path $ShadersDir | Out-Null }

# Copy shaders
Write-Host "Copying shaders..."
Copy-Item "$RepoDir\shaders\*" $ShadersDir -Force

# Clone blackhole
if (!(Test-Path $BlackholeDir)) {
    Write-Host "Cloning ghostty-blackhole..."
    git clone https://github.com/s0xDk/ghostty-blackhole.git $BlackholeDir
}

# Write base config
Write-Host "Writing config..."
@"
background-opacity = 0.7
clipboard-read = allow
"@ | Set-Content $ConfigFile -Encoding UTF8

# Copy theme script
Copy-Item "$RepoDir\shader-theme.ps1" $WinghosttyDir -Force

# Initialize theme
& "$WinghosttyDir\shader-theme.ps1" -Action "space"

Write-Host ""
Write-Host "Done! Reload Winghostty config with Ctrl+Shift+,"
Write-Host ""
Write-Host "To switch themes, run:"
Write-Host "  ghostty-theme next"
Write-Host "  ghostty-theme prev"
Write-Host "  ghostty-theme fx next"
Write-Host ""
Write-Host "To add 'ghostty-theme' command, add to your PowerShell profile:"
Write-Host '  Set-Alias ghostty-theme "$env:LOCALAPPDATA\winghostty\shader-theme.ps1"'
Write-Host '  # Profile path: $PROFILE'
