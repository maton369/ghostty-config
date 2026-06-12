# Ghostty Shader Theme System

A collection of 23 background shader themes and 4 cursor effect presets for the [Ghostty](https://ghostty.org/) terminal emulator, with a theme switcher that cycles through them via keybindings.

Works on **macOS** (Ghostty) and **Windows** ([Winghostty](https://github.com/amanthanvi/winghostty)).

## Features

- 23 animated background themes switchable at runtime
- 4 cursor effect presets (independently switchable)
- Automatic shader disable when opening editors (nvim/vim/vi)
- Starship prompt integration (shows current theme and keybinding hints)
- Cross-platform: macOS setup script + Windows PowerShell setup script

## Background Themes

Themes are cycled with `Ctrl+N` (next) / `Ctrl+P` (prev) on macOS.

| Theme | Effect | Category |
|-------|--------|----------|
| space | Colorful starfield + black hole | Space |
| pipboy | Fallout Pip-Boy green phosphor CRT | CRT/Retro |
| retro-term | Barrel distortion + scanlines + cyan-green tint | CRT/Retro |
| bettercrt | Barrel distortion + scanlines | CRT/Retro |
| game-crt | Cinematic CRT (aperture grille, ghosting, bloom) | CRT/Retro |
| crt | Classic CRT scanlines | CRT/Retro |
| rgbsplit | Chromatic aberration + pulsing glow | CRT/Retro |
| tft | TFT/LCD screen door overlay | CRT/Retro |
| dither | Ordered dithering (Bayer matrix posterization) | CRT/Retro |
| noir | Film noir (venetian blinds, smoke wisps, flicker) | CRT/Retro |
| water | Underwater caustic light patterns + text distortion | Nature |
| snow | Falling snow with parallax depth layers | Nature |
| sakura | Cherry blossom petals falling + moonlight | Nature |
| fire | Flames + rising sparks | Nature |
| liquid | Iridescent flowing caustic ridges | Nature |
| gradient | Slowly cycling color gradient | Ambient |
| cyberpunk | Synthwave + VHS glitch + pixel bug | Ambient |
| neon-vhs | VHS tracking glitch + neon bloom | Ambient |
| matrix | Falling green character rain | Ambient |
| gears | Industrial gears, belts, and gauges | Ambient |
| fireworks | Animated firework explosions | Ambient |
| pjsk | Project Sekai-style rotating crystal shards | Ambient |
| minimal | No background shader | - |

CRT/retro themes that warp the screen geometry (pipboy, retro-term, bettercrt, game-crt, crt) use the `fx_first` flag to draw cursor effects before the warp shader, keeping sparks aligned with the cursor.

## Cursor Effect Presets

Cursor effects are cycled independently with `Ctrl+F` (next) / `Ctrl+B` (prev) on macOS.

| Preset | Effect |
|--------|--------|
| particles | Blaze trail + lightning + sparks + slash + gravity |
| electric | Lightning arcs that scale with typing speed |
| aurora | Rotating gradient glow around the terminal border |
| none | No cursor effects |

## Setup

### macOS (Ghostty)

> **Prerequisites:** [Ghostty](https://ghostty.org/) installed.

```bash
# 1. Clone to Ghostty config directory
git clone https://github.com/maton369/ghostty-config.git ~/.config/ghostty

# 2. Run setup (clones blackhole shader, generates config)
~/.config/ghostty/setup.sh

# 3. Restart Ghostty (Cmd+Q, then reopen)
```

The setup script prints zsh keybinding snippets to add to `~/.zshrc`:

```zsh
# Ghostty shader toggle for editors
_ghostty_shaders_toggle="$HOME/.config/ghostty/shaders-toggle.sh"
for _cmd in nvim vim vi; do
  eval "function ${_cmd} {
    \"\$_ghostty_shaders_toggle\" off 2>/dev/null
    command ${_cmd} \"\$@\"
    \"\$_ghostty_shaders_toggle\" on 2>/dev/null
  }"
done

# Ghostty theme/fx cycling
_ghostty_theme="$HOME/.config/ghostty/shader-theme.sh"
function _ghostty_next_theme { local n; n=$("$_ghostty_theme" next 2>/dev/null); zle -M "theme: $n"; zle reset-prompt; }
function _ghostty_prev_theme { local n; n=$("$_ghostty_theme" prev 2>/dev/null); zle -M "theme: $n"; zle reset-prompt; }
function _ghostty_next_fx { local n; n=$("$_ghostty_theme" fx next 2>/dev/null); zle -M "fx: $n"; zle reset-prompt; }
function _ghostty_prev_fx { local n; n=$("$_ghostty_theme" fx prev 2>/dev/null); zle -M "fx: $n"; zle reset-prompt; }
zle -N _ghostty_next_theme; zle -N _ghostty_prev_theme
zle -N _ghostty_next_fx; zle -N _ghostty_prev_fx
bindkey '^n' _ghostty_next_theme; bindkey '^p' _ghostty_prev_theme
bindkey '^f' _ghostty_next_fx; bindkey '^b' _ghostty_prev_fx
```

#### Optional: Starship prompt integration

Add to `~/.config/starship.toml` to show the current theme and cursor preset in the right prompt:

```toml
right_format = "${custom.shader} ${custom.fx}"

[custom.shader]
command = 'cat /tmp/ghostty-shader-theme-name 2>/dev/null || echo "space"'
when = "true"
shell = ["bash", "--noprofile", "--norc"]
format = "[🌀 $output ^N/^P](dimmed white)"

[custom.fx]
command = 'cat /tmp/ghostty-shader-fx-name 2>/dev/null || echo "particles"'
when = "true"
shell = ["bash", "--noprofile", "--norc"]
format = "[⚡ $output ^F/^B](dimmed white)"
```

### Windows (Winghostty)

> **Prerequisites:** [Git](https://git-scm.com/downloads/win) installed.

```powershell
# 1. Install Winghostty
winget install AmanThanvi.winghostty

# 2. Clone this repo and run setup
git clone https://github.com/maton369/ghostty-config.git $env:TEMP\ghostty-config
& $env:TEMP\ghostty-config\setup-windows.ps1

# 3. Reload Winghostty config: Ctrl+Shift+,
```

The setup copies shaders to `%LOCALAPPDATA%\winghostty\shaders\` and creates the config at `%LOCALAPPDATA%\winghostty\config.ghostty`.

#### Theme switching on Windows

```powershell
# Add to your PowerShell profile ($PROFILE):
Set-Alias ghostty-theme "$env:LOCALAPPDATA\winghostty\shader-theme.ps1"
```

Then:
```powershell
ghostty-theme next          # Next background theme
ghostty-theme prev          # Previous background theme
ghostty-theme space         # Switch to specific theme
ghostty-theme list          # List all themes

ghostty-theme fx next       # Next cursor preset
ghostty-theme fx prev       # Previous cursor preset
ghostty-theme fx list       # List all presets
```

After switching, reload Winghostty with `Ctrl+Shift+,`.

## Keybinding Summary

| Key | Action | Platform |
|-----|--------|----------|
| `Ctrl+N` | Next background theme | macOS (zsh) |
| `Ctrl+P` | Previous background theme | macOS (zsh) |
| `Ctrl+F` | Next cursor effect preset | macOS (zsh) |
| `Ctrl+B` | Previous cursor effect preset | macOS (zsh) |
| `Ctrl+Shift+,` | Reload config | Windows (Winghostty) |

## CLI Usage (macOS)

```bash
shader-theme.sh next              # Next theme
shader-theme.sh prev              # Previous theme
shader-theme.sh list              # List themes (* = current)
shader-theme.sh <name>            # Switch to theme by name

shader-theme.sh fx next           # Next cursor preset
shader-theme.sh fx prev           # Previous cursor preset
shader-theme.sh fx list           # List presets
shader-theme.sh fx <name>         # Switch to preset by name
```

## How It Works

`shader-theme.sh` (bash) and `shader-theme.ps1` (PowerShell) rewrite the Ghostty/Winghostty config file, replacing `custom-shader` lines while preserving non-shader settings. On macOS, it sends `SIGUSR2` to Ghostty for hot-reload. On Windows, manual reload with `Ctrl+Shift+,` is required.

The `shaders-toggle.sh` script comments/uncomments shader lines when entering/exiting terminal editors, so shaders don't interfere with text editing.

## Black Hole

The "space" theme includes a black hole effect from [s0xDk/ghostty-blackhole](https://github.com/s0xDk/ghostty-blackhole). Both setup scripts clone it automatically.

## Credits

Shaders collected from:

- [0xhckr/ghostty-shaders](https://github.com/0xhckr/ghostty-shaders) — water, gradient, snow, fireworks, cubes, gears, ghost, fire, lava, dither, tft, bettercrt, in-game-crt, retro-terminal, rgbsplit
- [snedea/ghostty-themes](https://github.com/snedea/ghostty-themes) — sakura, cyberpunk, neon-vhs, pipboy, noir
- [fielding/ghostty-shader-adventures](https://github.com/fielding/ghostty-shader-adventures) — electric
- [jshiv/ghostty-shaders](https://github.com/jshiv/ghostty-shaders) — liquid-light
- [cmmichael/ghostty-aurora](https://github.com/cmmichael/ghostty-aurora) — aurora-border
- [Swizzzer/my-ghostty-shader](https://github.com/Swizzzer/my-ghostty-shader) — pjsk
- [hackr-sh/ghostty-shaders](https://github.com/hackr-sh/ghostty-shaders) — starfield-colors, crt, galaxy, inside-the-matrix, underwater, bloom
- [hondazn/dotfiles](https://github.com/hondazn/dotfiles) — cursor_blaze, cursor_lightning, sparks, slash, gravity
- [s0xDk/ghostty-blackhole](https://github.com/s0xDk/ghostty-blackhole) — black hole effect
