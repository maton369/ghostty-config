#!/bin/bash
# Setup Ghostty config on a new Mac.
# Run once after cloning this repo to ~/.config/ghostty/

set -e

CONFIG="$HOME/.config/ghostty/config"

# Write base config (non-shader settings)
cat > "$CONFIG" <<'EOF'
background-opacity = 0.7
macos-option-as-alt = true
clipboard-read = allow
shell-integration-features = cursor,sudo,title,ssh-env,ssh-terminfo,path
EOF

# Clone blackhole shader if not present
BLACKHOLE_DIR="$HOME/ghostty-blackhole"
if [ ! -d "$BLACKHOLE_DIR" ]; then
  echo "Cloning ghostty-blackhole..."
  git clone https://github.com/s0xDk/ghostty-blackhole.git "$BLACKHOLE_DIR"
fi

# Make scripts executable
chmod +x "$HOME/.config/ghostty/shader-theme.sh"
chmod +x "$HOME/.config/ghostty/shaders-toggle.sh"

# Initialize to space theme with particles cursor preset
echo "0" > /tmp/ghostty-shader-theme
echo "0" > /tmp/ghostty-shader-fx
"$HOME/.config/ghostty/shader-theme.sh" space

echo "Done! Restart Ghostty (Cmd+Q) to apply shaders."
echo ""
echo "Add to your .zshrc:"
echo '  # Ghostty shader toggle for editors'
echo '  _ghostty_shaders_toggle="$HOME/.config/ghostty/shaders-toggle.sh"'
echo '  for _cmd in nvim vim vi; do'
echo '    eval "function ${_cmd} {'
echo '      \"\$_ghostty_shaders_toggle\" off 2>/dev/null'
echo '      command ${_cmd} \"\$@\"'
echo '      \"\$_ghostty_shaders_toggle\" on 2>/dev/null'
echo '    }"'
echo '  done'
echo ''
echo '  # Ghostty theme/fx cycling'
echo '  _ghostty_theme="$HOME/.config/ghostty/shader-theme.sh"'
echo '  function _ghostty_next_theme { local n; n=$("$_ghostty_theme" next 2>/dev/null); zle -M "theme: $n"; zle reset-prompt; }'
echo '  function _ghostty_prev_theme { local n; n=$("$_ghostty_theme" prev 2>/dev/null); zle -M "theme: $n"; zle reset-prompt; }'
echo '  function _ghostty_next_fx { local n; n=$("$_ghostty_theme" fx next 2>/dev/null); zle -M "fx: $n"; zle reset-prompt; }'
echo '  function _ghostty_prev_fx { local n; n=$("$_ghostty_theme" fx prev 2>/dev/null); zle -M "fx: $n"; zle reset-prompt; }'
echo '  zle -N _ghostty_next_theme; zle -N _ghostty_prev_theme'
echo '  zle -N _ghostty_next_fx; zle -N _ghostty_prev_fx'
echo '  bindkey "^n" _ghostty_next_theme; bindkey "^p" _ghostty_prev_theme'
echo '  bindkey "^f" _ghostty_next_fx; bindkey "^b" _ghostty_prev_fx'
