# Ghostty Shader Theme System

15 background themes and 4 cursor effect presets for [Ghostty](https://ghostty.org/) terminal.

Works on **macOS** (Ghostty) and **Windows** ([Winghostty](https://github.com/amanthanvi/winghostty)).

## Themes

| Theme | Effect |
|-------|--------|
| space | Colorful starfield + black hole |
| pipboy | Fallout Pip-Boy CRT |
| water | Underwater caustics |
| snow | Falling snow |
| cyberpunk | Synthwave + VHS glitch |
| liquid | Iridescent flowing caustics |
| matrix | Matrix rain |
| gradient | Color cycling gradient |
| fireworks | Fireworks |
| sakura | Cherry blossom petals + moonlight |
| gears | Industrial gears & belts |
| fire | Fire + rising sparks |
| neon-vhs | VHS glitch + neon |
| pjsk | Project Sekai crystal shards |
| minimal | No shader |

## Cursor Effect Presets

| Preset | Effect |
|--------|--------|
| particles | blaze + lightning + sparks + slash + gravity |
| electric | Typing-speed lightning |
| aurora | Glowing border |
| none | No cursor effects |

## Setup — macOS

```bash
git clone https://github.com/maton369/ghostty-config.git ~/.config/ghostty
~/.config/ghostty/setup.sh
```

Restart Ghostty (Cmd+Q), then add keybindings to `~/.zshrc` (printed by setup.sh).

### Keybindings

| Key | Action |
|-----|--------|
| Ctrl+N / Ctrl+P | Cycle background themes |
| Ctrl+F / Ctrl+B | Cycle cursor effect presets |

## Setup — Windows (Winghostty)

Install [Winghostty](https://github.com/amanthanvi/winghostty):
```powershell
winget install AmanThanvi.winghostty
```

Then run the setup script in PowerShell:
```powershell
git clone https://github.com/maton369/ghostty-config.git $env:TEMP\ghostty-config
& $env:TEMP\ghostty-config\setup-windows.ps1
```

Reload config with `Ctrl+Shift+,`. Theme switching uses PowerShell:
```powershell
# Cycle themes
ghostty-theme next
ghostty-theme prev

# Switch to specific theme
ghostty-theme space
ghostty-theme pipboy

# Cycle cursor effects
ghostty-theme fx next
ghostty-theme fx prev
```

## Black Hole (optional)

The "space" theme includes a black hole effect from [s0xDk/ghostty-blackhole](https://github.com/s0xDk/ghostty-blackhole). It is cloned automatically by the setup scripts.

## Credits

Shaders sourced from:
- [0xhckr/ghostty-shaders](https://github.com/0xhckr/ghostty-shaders)
- [snedea/ghostty-themes](https://github.com/snedea/ghostty-themes)
- [fielding/ghostty-shader-adventures](https://github.com/fielding/ghostty-shader-adventures)
- [jshiv/ghostty-shaders](https://github.com/jshiv/ghostty-shaders)
- [cmmichael/ghostty-aurora](https://github.com/cmmichael/ghostty-aurora)
- [Swizzzer/my-ghostty-shader](https://github.com/Swizzzer/my-ghostty-shader)
- [hackr-sh/ghostty-shaders](https://github.com/hackr-sh/ghostty-shaders)
- [hondazn/dotfiles](https://github.com/hondazn/dotfiles)
- [s0xDk/ghostty-blackhole](https://github.com/s0xDk/ghostty-blackhole)
