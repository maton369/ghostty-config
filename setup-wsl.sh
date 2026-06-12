#!/bin/bash
# WSL2 (Ubuntu 等) + WSLg 上の Ghostty 用セットアップ。
# このリポジトリを ~/.config/ghostty/ にクローンした後、一度だけ実行する。
#
# 注意: WSL2 は Ghostty の公式サポート対象外。GPU の OpenGL 変換
# (Mesa d3d12) が失敗する環境ではソフトウェアレンダリングへの
# フォールバックが必要になる (本スクリプトが自動検出して案内する)。

set -e

CONFIG="$HOME/.config/ghostty/config"

# Ghostty 本体の確認
if ! command -v ghostty >/dev/null 2>&1; then
  echo "Ghostty が見つかりません。先にインストールしてください:"
  echo "  Ubuntu 24.04+ : sudo snap install ghostty --classic"
  echo "  Arch          : sudo pacman -S ghostty"
  echo "  その他        : https://ghostty.org/docs/install/binary"
  exit 1
fi

# ベース設定 (シェーダー以外) を書き込む
cat > "$CONFIG" <<'EOF'
background-opacity = 0.7
clipboard-read = allow
shell-integration-features = cursor,sudo,title,ssh-env,ssh-terminfo,path
EOF

# ブラックホールシェーダーのクローン
BLACKHOLE_DIR="$HOME/ghostty-blackhole"
if [ ! -d "$BLACKHOLE_DIR" ]; then
  echo "Cloning ghostty-blackhole..."
  git clone https://github.com/s0xDk/ghostty-blackhole.git "$BLACKHOLE_DIR"
fi

# スクリプトに実行権限を付与
chmod +x "$HOME/.config/ghostty/shader-theme.sh"
chmod +x "$HOME/.config/ghostty/shaders-toggle.sh"

# space テーマ + particles プリセットで初期化
echo "0" > /tmp/ghostty-shader-theme
echo "0" > /tmp/ghostty-shader-fx
"$HOME/.config/ghostty/shader-theme.sh" space

# WSLg の GPU OpenGL が使えるか確認
echo ""
if command -v glxinfo >/dev/null 2>&1; then
  renderer=$(glxinfo -B 2>/dev/null | grep "OpenGL renderer" || true)
  echo "検出されたレンダラー: ${renderer#*: }"
  case "$renderer" in
    *llvmpipe*|*softpipe*)
      echo "⚠ ソフトウェアレンダリングです。シェーダーは動作しますが重い可能性があります。"
      ;;
    *D3D12*)
      echo "✓ GPU パススルー (D3D12) が有効です。"
      ;;
  esac
else
  echo "glxinfo が無いためレンダラーを確認できません (mesa-utils で導入可)。"
fi

echo ""
echo "完了。Ghostty を起動してください。"
echo "起動時にクラッシュする場合はソフトウェアレンダリングを試す:"
echo "  LIBGL_ALWAYS_SOFTWARE=true GALLIUM_DRIVER=llvmpipe ghostty"
echo ""
echo "~/.zshrc (または ~/.bashrc) に追加するキーバインドは setup.sh と同じ。"
echo "詳細は README.md の「Setup — WSL」を参照。"
