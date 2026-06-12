# Switch Winghostty shader theme and cursor effects.
# Usage:
#   shader-theme.ps1 [-Action] next|prev|list|<theme-name>
#   shader-theme.ps1 [-Action] fx [-FxAction] next|prev|list|<preset-name>

param(
    [Parameter(Position=0)]
    [string]$Action = "next",
    [Parameter(Position=1)]
    [string]$FxAction = "next"
)

$WinghosttyDir = "$env:LOCALAPPDATA\winghostty"
$Config = "$WinghosttyDir\config.ghostty"
$ShadersDir = "$WinghosttyDir\shaders"
$BlackholeDir = "$env:USERPROFILE\ghostty-blackhole\blackhole.glsl"
$ThemeState = "$env:TEMP\ghostty-shader-theme"
$FxState = "$env:TEMP\ghostty-shader-fx"
$ThemeNameFile = "$env:TEMP\ghostty-shader-theme-name"
$FxNameFile = "$env:TEMP\ghostty-shader-fx-name"

# Cursor effect presets
$CursorPresets = @(
    @{ Name="particles"; Shaders=@("cursor_blaze.glsl","cursor_lightning.glsl","sparks.glsl","slash.glsl","gravity.glsl") },
    @{ Name="electric"; Shaders=@("electric.glsl") },
    @{ Name="aurora"; Shaders=@("aurora-border.glsl") },
    @{ Name="none"; Shaders=@() }
)

# Themes: Name, Shader, Blackhole, FxFirst
$Themes = @(
    @{ Name="space"; Shader="starfield-colors.glsl"; Blackhole=$true; FxFirst=$false },
    @{ Name="pipboy"; Shader="pipboy.glsl"; Blackhole=$false; FxFirst=$true },
    @{ Name="retro-term"; Shader="retro-terminal.glsl"; Blackhole=$false; FxFirst=$true },
    @{ Name="game-crt"; Shader="in-game-crt.glsl"; Blackhole=$false; FxFirst=$true },
    @{ Name="tft"; Shader="tft.glsl"; Blackhole=$false; FxFirst=$false },
    @{ Name="water"; Shader="water.glsl"; Blackhole=$false; FxFirst=$false },
    @{ Name="snow"; Shader="snow.glsl"; Blackhole=$false; FxFirst=$false },
    @{ Name="cyberpunk"; Shader="cyberpunk.glsl"; Blackhole=$false; FxFirst=$false },
    @{ Name="liquid"; Shader="liquid-light.glsl"; Blackhole=$false; FxFirst=$false },
    @{ Name="matrix"; Shader="inside-the-matrix.glsl"; Blackhole=$false; FxFirst=$false },
    @{ Name="gradient"; Shader="gradient.glsl"; Blackhole=$false; FxFirst=$false },
    @{ Name="fireworks"; Shader="fireworks.glsl"; Blackhole=$false; FxFirst=$false },
    @{ Name="sakura"; Shader="sakura.glsl"; Blackhole=$false; FxFirst=$false },
    @{ Name="gears"; Shader="gears.glsl"; Blackhole=$false; FxFirst=$false },
    @{ Name="fire"; Shader="fire.glsl"; Blackhole=$false; FxFirst=$false },
    @{ Name="neon-vhs"; Shader="neon-vhs.glsl"; Blackhole=$false; FxFirst=$false },
    @{ Name="pjsk"; Shader="pjsk.glsl"; Blackhole=$false; FxFirst=$false },
    @{ Name="minimal"; Shader=""; Blackhole=$false; FxFirst=$false }
)

function Read-Index($path) {
    if (Test-Path $path) { [int](Get-Content $path -Raw).Trim() } else { 0 }
}

function Get-CursorShaderLines {
    $idx = Read-Index $FxState
    $preset = $CursorPresets[$idx]
    foreach ($s in $preset.Shaders) {
        if ($s) { "custom-shader = $ShadersDir\$s" }
    }
}

function Write-GhosttyConfig($themeIdx) {
    $theme = $Themes[$themeIdx]

    # Read non-shader lines from existing config
    $header = @()
    if (Test-Path $Config) {
        $header = Get-Content $Config | Where-Object {
            $_ -notmatch '^#?custom-shader' -and $_ -notmatch '^#?custom-shader-animation'
        }
    }

    $lines = @()
    $lines += $header

    $fxLines = Get-CursorShaderLines

    # FxFirst: cursor effects before theme shader (for CRT warp alignment)
    if ($theme.FxFirst) { $lines += $fxLines }

    if ($theme.Shader) {
        $lines += "custom-shader = $ShadersDir\$($theme.Shader)"
    }
    if ($theme.Blackhole -and (Test-Path $BlackholeDir)) {
        $lines += "custom-shader = $BlackholeDir"
    }

    if (-not $theme.FxFirst) { $lines += $fxLines }

    $lines += "custom-shader-animation = true"

    $lines | Set-Content $Config -Encoding UTF8

    Set-Content $ThemeState $themeIdx
    Set-Content $ThemeNameFile $theme.Name

    Write-Output $theme.Name
}

function Write-Fx($fxIdx) {
    Set-Content $FxState $fxIdx
    Set-Content $FxNameFile $CursorPresets[$fxIdx].Name
    $themeIdx = Read-Index $ThemeState
    Write-GhosttyConfig $themeIdx | Out-Null
    Write-Output $CursorPresets[$fxIdx].Name
}

# --- FX subcommand ---
if ($Action -eq "fx") {
    $fxCount = $CursorPresets.Count
    switch ($FxAction) {
        "list" {
            $cur = Read-Index $FxState
            for ($i = 0; $i -lt $fxCount; $i++) {
                $mark = if ($i -eq $cur) { "* " } else { "  " }
                Write-Output "$mark$($CursorPresets[$i].Name)"
            }
        }
        "next" {
            $idx = ((Read-Index $FxState) + 1) % $fxCount
            Write-Fx $idx
        }
        "prev" {
            $idx = ((Read-Index $FxState) - 1 + $fxCount) % $fxCount
            Write-Fx $idx
        }
        default {
            $found = $false
            for ($i = 0; $i -lt $fxCount; $i++) {
                if ($CursorPresets[$i].Name -eq $FxAction) {
                    Write-Fx $i
                    $found = $true
                    break
                }
            }
            if (-not $found) { Write-Error "Unknown fx: $FxAction" }
        }
    }
    exit
}

# --- Theme subcommand ---
$themeCount = $Themes.Count
switch ($Action) {
    "list" {
        $cur = Read-Index $ThemeState
        for ($i = 0; $i -lt $themeCount; $i++) {
            $mark = if ($i -eq $cur) { "* " } else { "  " }
            Write-Output "$mark$($Themes[$i].Name)"
        }
    }
    "next" {
        $idx = ((Read-Index $ThemeState) + 1) % $themeCount
        Write-GhosttyConfig $idx
    }
    "prev" {
        $idx = ((Read-Index $ThemeState) - 1 + $themeCount) % $themeCount
        Write-GhosttyConfig $idx
    }
    default {
        $found = $false
        for ($i = 0; $i -lt $themeCount; $i++) {
            if ($Themes[$i].Name -eq $Action) {
                Write-GhosttyConfig $i
                $found = $true
                break
            }
        }
        if (-not $found) { Write-Error "Unknown theme: $Action" }
    }
}
