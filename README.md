# Ghostty シェーダーテーマシステム

[Ghostty](https://ghostty.org/) ターミナル用の背景シェーダーテーマ 23 種とカーソルエフェクトプリセット 4 種を、キーバインドで切り替えられる仕組みです。

**macOS** (Ghostty) と **Windows** ([Winghostty](https://github.com/amanthanvi/winghostty)) に対応しています。

## 機能

- 23 種のアニメーション背景テーマをランタイムで切り替え
- 4 種のカーソルエフェクトプリセット（背景テーマとは独立して切り替え可能）
- エディタ起動時にシェーダーを自動オフ（nvim / vim / vi）
- Starship プロンプト連携（現在のテーマ名・キーバインドのヒントを表示）
- クロスプラットフォーム：macOS 用 bash スクリプト＋Windows 用 PowerShell スクリプト

## 背景テーマ一覧

macOS では `Ctrl+N`（次）/ `Ctrl+P`（前）で切り替えます。

| テーマ | 効果 | カテゴリ |
|--------|------|----------|
| space | カラフル星空＋ブラックホール | 宇宙 |
| pipboy | Fallout Pip-Boy 風グリーン CRT | CRT / レトロ |
| retro-term | 樽型歪み＋走査線＋シアン色 | CRT / レトロ |
| bettercrt | 樽型歪み＋走査線 | CRT / レトロ |
| game-crt | ゲーム風 CRT（アパーチャグリル・ゴースト・ブルーム） | CRT / レトロ |
| crt | クラシック CRT 走査線 | CRT / レトロ |
| rgbsplit | 色収差＋脈動するグロー | CRT / レトロ |
| tft | TFT/LCD スクリーンドア効果 | CRT / レトロ |
| dither | 順序ディザリング（バイヤー行列ポスタライズ） | CRT / レトロ |
| noir | フィルム・ノワール（ブラインド影・煙・フリッカー） | CRT / レトロ |
| water | 水中コースティクス＋テキスト歪み | 自然 |
| snow | パララックスで降る雪 | 自然 |
| sakura | 桜の花びらが舞い落ちる＋月光 | 自然 |
| fire | 炎＋上昇する火の粉 | 自然 |
| liquid | 虹色に流れるコースティクス光 | 自然 |
| gradient | ゆっくり変化する色グラデーション | 雰囲気 |
| cyberpunk | シンセウェーブ＋VHS グリッチ＋ドット絵の虫 | 雰囲気 |
| neon-vhs | VHS トラッキングノイズ＋ネオンブルーム | 雰囲気 |
| matrix | 緑色の文字が降る雨 | 雰囲気 |
| gears | 歯車・ベルト・メーター | 雰囲気 |
| fireworks | 打ち上げ花火 | 雰囲気 |
| pjsk | プロセカ風の回転する結晶片 | 雰囲気 |
| minimal | シェーダーなし | - |

画面を幾何学的に歪める CRT 系テーマ（pipboy, retro-term, bettercrt, game-crt, crt）では `fx_first` フラグにより、カーソルエフェクトを歪みシェーダーの前に描画し、火花がカーソル位置とずれないようにしています。

## カーソルエフェクトプリセット

macOS では `Ctrl+F`（次）/ `Ctrl+B`（前）で独立して切り替えます。

| プリセット | 効果 |
|-----------|------|
| particles | 炎の軌跡＋稲妻＋火花＋斬撃＋重力パーティクル |
| electric | タイピング速度に応じた稲妻アーク |
| aurora | ターミナル枠を回転するグラデーション光 |
| none | カーソルエフェクトなし |

## セットアップ

### macOS (Ghostty)

> **前提条件:** [Ghostty](https://ghostty.org/) がインストール済みであること。

```bash
# 1. Ghostty の設定ディレクトリにクローン
git clone https://github.com/maton369/ghostty-config.git ~/.config/ghostty

# 2. セットアップ実行（ブラックホールシェーダーのクローン・設定ファイル生成）
~/.config/ghostty/setup.sh

# 3. Ghostty を再起動（Cmd+Q してから再度開く）
```

セットアップスクリプトが `~/.zshrc` に追加するキーバインド設定を出力します：

```zsh
# エディタ起動時にシェーダーをオフにする
_ghostty_shaders_toggle="$HOME/.config/ghostty/shaders-toggle.sh"
for _cmd in nvim vim vi; do
  eval "function ${_cmd} {
    \"\$_ghostty_shaders_toggle\" off 2>/dev/null
    command ${_cmd} \"\$@\"
    \"\$_ghostty_shaders_toggle\" on 2>/dev/null
  }"
done

# テーマ・エフェクト切り替え
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

#### オプション：Starship プロンプト連携

`~/.config/starship.toml` に追加すると、右プロンプトに現在のテーマとプリセット名が表示されます：

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

> **前提条件:** [Git](https://git-scm.com/downloads/win) がインストール済みであること。

```powershell
# 1. Winghostty をインストール
winget install AmanThanvi.winghostty

# 2. リポジトリをクローンしてセットアップ
git clone https://github.com/maton369/ghostty-config.git $env:TEMP\ghostty-config
& $env:TEMP\ghostty-config\setup-windows.ps1

# 3. Winghostty の設定をリロード: Ctrl+Shift+,
```

セットアップスクリプトは `%LOCALAPPDATA%\winghostty\shaders\` にシェーダーをコピーし、`%LOCALAPPDATA%\winghostty\config.ghostty` に設定ファイルを生成します。

#### Windows でのテーマ切り替え

```powershell
# PowerShell プロファイル ($PROFILE) にエイリアスを追加:
Set-Alias ghostty-theme "$env:LOCALAPPDATA\winghostty\shader-theme.ps1"
```

使い方：
```powershell
ghostty-theme next          # 次の背景テーマ
ghostty-theme prev          # 前の背景テーマ
ghostty-theme space         # テーマを名前で指定
ghostty-theme list          # テーマ一覧

ghostty-theme fx next       # 次のカーソルプリセット
ghostty-theme fx prev       # 前のカーソルプリセット
ghostty-theme fx list       # プリセット一覧
```

テーマ切り替え後は `Ctrl+Shift+,` で設定をリロードしてください。

## キーバインド一覧

| キー | 操作 | プラットフォーム |
|------|------|-----------------|
| `Ctrl+N` | 次の背景テーマ | macOS (zsh) |
| `Ctrl+P` | 前の背景テーマ | macOS (zsh) |
| `Ctrl+F` | 次のカーソルエフェクト | macOS (zsh) |
| `Ctrl+B` | 前のカーソルエフェクト | macOS (zsh) |
| `Ctrl+Shift+,` | 設定リロード | Windows (Winghostty) |

## CLI の使い方（macOS）

```bash
shader-theme.sh next              # 次のテーマ
shader-theme.sh prev              # 前のテーマ
shader-theme.sh list              # テーマ一覧（* が現在のテーマ）
shader-theme.sh <テーマ名>         # テーマを名前で指定

shader-theme.sh fx next           # 次のカーソルプリセット
shader-theme.sh fx prev           # 前のカーソルプリセット
shader-theme.sh fx list           # プリセット一覧
shader-theme.sh fx <プリセット名>  # プリセットを名前で指定
```

## 仕組み

`shader-theme.sh`（bash）と `shader-theme.ps1`（PowerShell）は Ghostty / Winghostty の設定ファイルを書き換え、`custom-shader` 行を差し替えつつ、シェーダー以外の設定はそのまま保持します。macOS では `SIGUSR2` シグナルで Ghostty をホットリロードします。Windows では `Ctrl+Shift+,` で手動リロードが必要です。

`shaders-toggle.sh` はエディタに入る / 出るときにシェーダー行をコメントアウト / コメント解除し、テキスト編集の邪魔にならないようにします。

## ブラックホール

「space」テーマには [s0xDk/ghostty-blackhole](https://github.com/s0xDk/ghostty-blackhole) のブラックホールエフェクトが含まれます。両プラットフォームのセットアップスクリプトが自動でクローンします。

## クレジット

シェーダーの出典：

- [0xhckr/ghostty-shaders](https://github.com/0xhckr/ghostty-shaders) — water, gradient, snow, fireworks, gears, fire, dither, tft, bettercrt, in-game-crt, retro-terminal, rgbsplit
- [snedea/ghostty-themes](https://github.com/snedea/ghostty-themes) — sakura, cyberpunk, neon-vhs, pipboy, noir
- [fielding/ghostty-shader-adventures](https://github.com/fielding/ghostty-shader-adventures) — electric
- [jshiv/ghostty-shaders](https://github.com/jshiv/ghostty-shaders) — liquid-light
- [cmmichael/ghostty-aurora](https://github.com/cmmichael/ghostty-aurora) — aurora-border
- [Swizzzer/my-ghostty-shader](https://github.com/Swizzzer/my-ghostty-shader) — pjsk
- [hackr-sh/ghostty-shaders](https://github.com/hackr-sh/ghostty-shaders) — starfield-colors, crt, inside-the-matrix
- [hondazn/dotfiles](https://github.com/hondazn/dotfiles) — cursor_blaze, cursor_lightning, sparks, slash, gravity
- [s0xDk/ghostty-blackhole](https://github.com/s0xDk/ghostty-blackhole) — ブラックホールエフェクト
