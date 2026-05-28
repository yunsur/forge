#!/usr/bin/env bash
_SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$_SCRIPT_DIR/../shell/forge/common.sh"

# @name: jetbrains-mono-nf
# @repo: ryanoasis/nerd-fonts

FONT_DIR="${FONT_DIR:-$HOME/.local/share/fonts}"

get_latest() { github_latest "ryanoasis/nerd-fonts"; }

upgrade() {
    local latest; latest=$(get_latest)
    [ -z "$latest" ] && { err "无法获取最新版本"; exit 1; }
    local url="https://github.com/ryanoasis/nerd-fonts/releases/download/${latest}/JetBrainsMono.zip"
    fetch "jetbrains-mono-nf" "$url" "zip"
    mkdir -p "$FONT_DIR"
    local src="$TOOLS_DIR/jetbrains-mono-nf"
    if compgen -G "$src/*.ttf" >/dev/null 2>&1; then
        cp "$src"/*.ttf "$FONT_DIR/"
        fc-cache -fv "$FONT_DIR" >/dev/null 2>&1
    elif [ -f "$src/JetBrainsMono.zip" ]; then
        unzip -q -o "$src/JetBrainsMono.zip" -d "$FONT_DIR"
        fc-cache -fv "$FONT_DIR" >/dev/null 2>&1
    fi
    mkdir -p "$TOOLS_DIR/jetbrains-mono-nf"
}

install_from() {
    local file="$1"
    _log "安装" "JetBrainsMono Nerd Font → $FONT_DIR"
    mkdir -p "$FONT_DIR"
    unzip -q -o "$file" -d "$FONT_DIR"
    fc-cache -fv "$FONT_DIR" >/dev/null 2>&1
    mkdir -p "$TOOLS_DIR/jetbrains-mono-nf"
    ok "JetBrainsMono Nerd Font"
}
