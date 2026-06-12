#!/bin/bash
# Switch Ghostty shader theme and cursor effects.
# Usage:
#   shader-theme.sh [next|prev|list|<theme-name>]        — background theme
#   shader-theme.sh fx [next|prev|list|<preset-name>]    — cursor effects

CONFIG="$HOME/.config/ghostty/config"
SHADERS="$HOME/.config/ghostty/shaders"
BLACKHOLE="$HOME/ghostty-blackhole/blackhole.glsl"
THEME_STATE="/tmp/ghostty-shader-theme"
FX_STATE="/tmp/ghostty-shader-fx"

# cursor effect presets = (name:shader1,shader2,...)
CURSOR_PRESETS=(
  "particles:$SHADERS/cursor_blaze.glsl,$SHADERS/cursor_lightning.glsl,$SHADERS/sparks.glsl,$SHADERS/slash.glsl,$SHADERS/gravity.glsl"
  "electric:$SHADERS/electric.glsl"
  "aurora:$SHADERS/aurora-border.glsl"
  "none:"
)

# theme = (display_name:background_shader:include_blackhole[:fx_first])
# fx_first=1 — テーマが画面を幾何学的に歪める (CRT カーブ等) 場合、
# カーソルエフェクトを先に描画してから歪ませることで火花の位置を文字と一致させる
THEMES=(
  "space:$SHADERS/starfield-colors.glsl:1"
  "pipboy:$SHADERS/pipboy.glsl:0:1"
  "retro-term:$SHADERS/retro-terminal.glsl:0:1"
  "bettercrt:$SHADERS/bettercrt.glsl:0:1"
  "game-crt:$SHADERS/in-game-crt.glsl:0:1"
  "crt:$SHADERS/crt.glsl:0:1"
  "rgbsplit:$SHADERS/glow-rgbsplit-twitchy.glsl:0"
  "tft:$SHADERS/tft.glsl:0"
  "dither:$SHADERS/dither.glsl:0"
  "noir:$SHADERS/noir-grain.glsl:0"
  "water:$SHADERS/water.glsl:0"
  "snow:$SHADERS/snow.glsl:0"
  "cyberpunk:$SHADERS/cyberpunk.glsl:0"
  "liquid:$SHADERS/liquid-light.glsl:0"
  "matrix:$SHADERS/inside-the-matrix.glsl:0"
  "gradient:$SHADERS/gradient.glsl:0"
  "fireworks:$SHADERS/fireworks.glsl:0"
  "sakura:$SHADERS/sakura.glsl:0"
  "gears:$SHADERS/gears.glsl:0"
  "fire:$SHADERS/fire.glsl:0"
  "neon-vhs:$SHADERS/neon-vhs.glsl:0"
  "pjsk:$SHADERS/pjsk.glsl:0"
  "minimal::0"
)

theme_count=${#THEMES[@]}
fx_count=${#CURSOR_PRESETS[@]}

read_index() { cat "$1" 2>/dev/null || echo "0"; }

get_cursor_shaders() {
  local idx
  idx=$(read_index "$FX_STATE")
  local entry="${CURSOR_PRESETS[$idx]}"
  echo "${entry#*:}"
}

reload_ghostty() {
  ps -eo pid,comm | while read pid comm; do
    case "$comm" in */ghostty) kill -SIGUSR2 "$pid" 2>/dev/null ;; esac
  done
}

emit_cursor_shaders() {
  IFS=',' read -ra fx_arr <<< "$(get_cursor_shaders)"
  for s in "${fx_arr[@]}"; do
    [ -n "$s" ] && echo "custom-shader = $s"
  done
}

write_config() {
  local theme_idx=$1
  local entry="${THEMES[$theme_idx]}"
  local name bg bh fx_first
  IFS=':' read -r name bg bh fx_first <<< "$entry"

  local header
  header=$(grep -v '^custom-shader\|^#custom-shader\|^custom-shader-animation\|^#custom-shader-animation' "$CONFIG")

  {
    echo "$header"
    # fx_first: draw cursor effects before the warping theme shader so they
    # get warped together with the screen and stay aligned with the cursor
    [ "$fx_first" = "1" ] && emit_cursor_shaders
    [ -n "$bg" ] && echo "custom-shader = $bg"
    [ "$bh" = "1" ] && echo "custom-shader = $BLACKHOLE"
    [ "$fx_first" != "1" ] && emit_cursor_shaders
    echo "custom-shader-animation = true"
  } > "$CONFIG"

  echo "$theme_idx" > "$THEME_STATE"
  echo "$name" > /tmp/ghostty-shader-theme-name
  reload_ghostty
  echo "$name"
}

write_fx() {
  local fx_idx=$1
  local entry="${CURSOR_PRESETS[$fx_idx]}"
  local name="${entry%%:*}"
  echo "$fx_idx" > "$FX_STATE"
  echo "$name" > /tmp/ghostty-shader-fx-name
  # rewrite config with current theme + new fx
  local theme_idx
  theme_idx=$(read_index "$THEME_STATE")
  write_config "$theme_idx" > /dev/null
  echo "$name"
}

# --- cursor effects subcommand ---
if [ "$1" = "fx" ]; then
  case "${2:-next}" in
    list)
      local_idx=$(read_index "$FX_STATE")
      for i in "${!CURSOR_PRESETS[@]}"; do
        name="${CURSOR_PRESETS[$i]%%:*}"
        if [ "$i" -eq "$local_idx" ]; then
          echo "* $name"
        else
          echo "  $name"
        fi
      done
      ;;
    next)
      idx=$(( ($(read_index "$FX_STATE") + 1) % fx_count ))
      write_fx "$idx"
      ;;
    prev)
      idx=$(( ($(read_index "$FX_STATE") - 1 + fx_count) % fx_count ))
      write_fx "$idx"
      ;;
    *)
      for i in "${!CURSOR_PRESETS[@]}"; do
        if [ "${CURSOR_PRESETS[$i]%%:*}" = "$2" ]; then
          write_fx "$i"
          exit 0
        fi
      done
      echo "Unknown fx: $2" >&2
      exit 1
      ;;
  esac
  exit 0
fi

# --- background theme subcommand ---
case "${1:-next}" in
  list)
    local_idx=$(read_index "$THEME_STATE")
    for i in "${!THEMES[@]}"; do
      name="${THEMES[$i]%%:*}"
      if [ "$i" -eq "$local_idx" ]; then
        echo "* $name"
      else
        echo "  $name"
      fi
    done
    ;;
  next)
    idx=$(( ($(read_index "$THEME_STATE") + 1) % theme_count ))
    write_config "$idx"
    ;;
  prev)
    idx=$(( ($(read_index "$THEME_STATE") - 1 + theme_count) % theme_count ))
    write_config "$idx"
    ;;
  *)
    for i in "${!THEMES[@]}"; do
      if [ "${THEMES[$i]%%:*}" = "$1" ]; then
        write_config "$i"
        exit 0
      fi
    done
    echo "Unknown theme: $1" >&2
    exit 1
    ;;
esac
