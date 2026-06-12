#!/bin/bash
# Toggle Ghostty shaders on/off by commenting/uncommenting config lines.
# Usage: shaders-toggle.sh on|off

CONFIG="$HOME/.config/ghostty/config"

case "$1" in
  off)
    sed -i '' 's/^custom-shader/#custom-shader/' "$CONFIG"
    sed -i '' 's/^custom-shader-animation/#custom-shader-animation/' "$CONFIG"
    ;;
  on)
    sed -i '' 's/^#custom-shader/custom-shader/' "$CONFIG"
    ;;
  *)
    echo "Usage: $0 on|off" >&2
    exit 1
    ;;
esac

# Reload Ghostty (ps, not pgrep — Ghostty is an ancestor)
ps -eo pid,comm | while read pid comm; do
  case "$comm" in */ghostty) kill -SIGUSR2 "$pid" 2>/dev/null ;; esac
done
