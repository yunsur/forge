#!/usr/bin/env bash
# 公共函数库（被 manifest、forge 和 init.sh source）

_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
AI_HOME="${AI_HOME:-$HOME/ai}"
TOOLS_DIR="$AI_HOME/tools"
RUNTIMES_DIR="$AI_HOME/runtimes"
TMP_DIR="$_ROOT/download/.tmp"

OS="${OS:-linux}"
ARCH="${ARCH:-amd64}"

# 开发环境检测：在 forge 仓库内运行时拒绝 init
is_forge_dev() {
    [ -d "$_ROOT/.git" ] && [ "${FORGE_SKIP_DEV_CHECK:-0}" != "1" ]
}

# 颜色
R='\033[0;31m' G='\033[0;32m' Y='\033[1;33m' B='\033[0;34m'
D='\033[2m' NC='\033[0m' BOLD='\033[1m'

_log()  { echo -e "${B}[$1]${NC} $2"; }
ok()    { echo -e "  ${G}✓${NC} $1"; }
warn()  { echo -e "  ${Y}!${NC} $1" >&2; }
err()   { echo -e "  ${R}✗${NC} $1" >&2; }

# curl 通用选项（代理和 token）— 设置全局数组 _CURL_OPTS
_curl_base_opts() {
    _CURL_OPTS+=(--connect-timeout 10 --retry 3 --retry-delay 2 --retry-all-errors)
    [ -n "${https_proxy:-${HTTPS_PROXY:-}}" ] && _CURL_OPTS+=(--proxy "${https_proxy:-$HTTPS_PROXY}")
    [ -n "${http_proxy:-${HTTP_PROXY:-}}" ] && _CURL_OPTS+=(--proxy "${http_proxy:-$HTTP_PROXY}")
    [ -n "${GITHUB_TOKEN:-}" ] && _CURL_OPTS+=(-H "Authorization: Bearer $GITHUB_TOKEN")
}

# API 请求用（短超时）
_curl_opts() {
    _CURL_OPTS=(-fsSL --max-time 30)
    _curl_base_opts
}

# 文件下载用（无 max-time 限制）
_curl_download_opts() {
    _CURL_OPTS=(-fSL --retry-max-time 0)
    _curl_base_opts
    _CURL_OPTS+=(-H "User-Agent: Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/136.0.0.0 Safari/537.36")
}

# GitHub API: 获取最新 release tag
github_latest() {
    local repo="$1" version=""
    _curl_opts
    version=$(curl "${_CURL_OPTS[@]}" "https://api.github.com/repos/${repo}/releases/latest" 2>/dev/null \
        | grep '"tag_name"' | head -1 \
        | sed -E 's/.*"tag_name"[[:space:]]*:[[:space:]]*"([^"]+)".*/\1/' || true)
    if [ -z "$version" ]; then
        _curl_opts
        version=$(curl "${_CURL_OPTS[@]}" "https://github.com/${repo}/releases/latest" 2>/dev/null \
            | grep -o 'releases/tag/[^"]*' \
            | sed -E 's|releases/tag/||' \
            | grep '[0-9]' | head -1 || true)
    fi
    echo "$version"
}

# 下载 + 解压到 tools/<name>
fetch() {
    local name="$1" url="$2" format="$3" mode="${4:-}" binary_name="${5:-}"
    _log "下载" "$name"
    local dest="$TOOLS_DIR/$name" tmp="$TMP_DIR/$name"
    mkdir -p "$dest" "$TMP_DIR"
    _curl_download_opts; curl "${_CURL_OPTS[@]}" -o "$tmp" "$url"
    _extract "$tmp" "$dest" "$format" "$mode" "$binary_name"
    rm -f "$tmp"
    ok "$name"
}

# 下载 + 解压到指定目录
fetch_to() {
    local dest="$1" url="$2" format="$3" mode="${4:-}" binary_name="${5:-}"
    local tmp="$TMP_DIR/_fetch_$$"
    mkdir -p "$dest" "$TMP_DIR"
    _curl_download_opts; curl "${_CURL_OPTS[@]}" -o "$tmp" "$url"
    _extract "$tmp" "$dest" "$format" "$mode" "$binary_name"
    rm -f "$tmp"
}

# 抑制 macOS LIBARCHIVE xattr 警告（GNU tar 不认识这些头）
_tar_quiet() { "$@" 2> >(grep -v 'LIBARCHIVE.xattr' >&2); }

_extract() {
    local tmp="$1" dest="$2" format="$3" mode="$4" binary_name="$5"
    case "$format" in
        tar.xz|txz)
            case "$mode" in
                strip1) _tar_quiet tar -xJf "$tmp" -C "$dest" --strip-components=1 || return 1 ;;
                flat)   _tar_quiet tar -xJf "$tmp" -C "$dest" || return 1 ;;
                *) _tar_quiet tar -xJf "$tmp" -C "$dest" || return 1 ;;
            esac
            ;;
        tar.gz|tgz)
            case "$mode" in
                strip1) _tar_quiet tar -xzf "$tmp" -C "$dest" --strip-components=1 || return 1 ;;
                flat)   _tar_quiet tar -xzf "$tmp" -C "$dest" || return 1 ;;
                flat-binary)
                    _tar_quiet tar -xzf "$tmp" -C "$dest" || return 1
                    local bin
                    bin=$(find "$dest" -type f -name "$binary_name" | head -1)
                    if [ -z "$bin" ]; then
                        bin=$(find "$dest" -type f -name "${binary_name}_*" | head -1)
                    fi
                    if [ -n "$bin" ] && [ "$bin" != "$dest/$binary_name" ]; then
                        mv "$bin" "$dest/$binary_name"
                        find "$dest" -mindepth 1 -maxdepth 1 ! -name "$binary_name" -exec rm -rf {} + 2>/dev/null
                    fi
                    [ -f "$dest/$binary_name" ] && chmod +x "$dest/$binary_name"
                    ;;
                *) _tar_quiet tar -xzf "$tmp" -C "$dest" || return 1 ;;
            esac
            ;;
        zip)
            unzip -q -o "$tmp" -d "$dest" || return 1
            if [ "$mode" = "flat-binary" ] && [ -n "$binary_name" ]; then
                local bin
                bin=$(find "$dest" -type f -name "$binary_name" | head -1)
                if [ -n "$bin" ] && [ "$bin" != "$dest/$binary_name" ]; then
                    mv "$bin" "$dest/$binary_name"
                    find "$dest" -mindepth 1 ! -name "$binary_name" -exec rm -rf {} + 2>/dev/null
                fi
                chmod +x "$dest/$binary_name"
            fi
            ;;
        binary)
            cp "$tmp" "$dest/$binary_name"
            chmod +x "$dest/$binary_name"
            ;;
    esac
}

# 将二进制链接到 ai/bin/
link_binary() {
    local src="$1" name="${2:-$(basename "$1")}"
    [ -f "$src" ] || return 0
    mkdir -p "$AI_HOME/bin"
    ln -sf "$src" "$AI_HOME/bin/$name"
}

# 更新脚本中的 VERSION 变量
update_script_version() {
    local script="$1" version="$2"
    if [ -f "$script" ] && grep -q '^VERSION=' "$script" 2>/dev/null; then
        sed -i.bak "s|^VERSION=.*|VERSION=\"${version}\"|" "$script"
        rm -f "${script}.bak"
    fi
}

# ── 下载专用函数（forge download 使用）────────────────────

# 只下载不解压，保存到 download/
download_only() {
    local name="$1" url="$2" filename="${3:-}"
    [ -z "$filename" ] && filename=$(basename "$url" | sed 's/?.*//')
    local dest="$_ROOT/download"
    mkdir -p "$dest"
    _log "下载" "$name → $filename"
    _curl_download_opts; curl "${_CURL_OPTS[@]}" -o "$dest/$filename" "$url"
    ok "$name"
}

# 从本地文件解压（供 manifest 的 install_from() 调用）
install_from_file() {
    local file="$1" name="$2" format="$3" mode="$4" binary_name="${5:-}"
    local dest="$TOOLS_DIR/$name"
    mkdir -p "$dest"
    _extract "$file" "$dest" "$format" "$mode" "$binary_name"
}

# ── Forge CLI 共享函数 ────────────────────────────────────

REGISTRY_DIR="${REGISTRY_DIR:-$_ROOT/registry}"
LOCK_FILE="${LOCK_FILE:-$_ROOT/download/versions.lock}"

load_registry() {
    REGISTRY=()
    for f in "$REGISTRY_DIR"/*.sh; do
        [ -f "$f" ] || continue
        REGISTRY+=("$f")
    done
}

meta_get() {
    grep "^# @${2}:" "$1" 2>/dev/null | head -1 | sed "s/^# @${2}: *//" || true
}

get_installed() {
    [ -f "$LOCK_FILE" ] && grep "^${1}|" "$LOCK_FILE" 2>/dev/null | tail -1 | cut -d'|' -f2 || true
}

set_installed() {
    mkdir -p "$(dirname "$LOCK_FILE")"
    if [ -f "$LOCK_FILE" ] && grep -q "^${1}|" "$LOCK_FILE" 2>/dev/null; then
        sed -i.bak "s#^${1}|.*#${1}|${2}|$(date +%Y-%m-%d)#" "$LOCK_FILE"
        rm -f "$LOCK_FILE.bak"
    else
        echo "${1}|${2}|$(date +%Y-%m-%d)" >> "$LOCK_FILE"
    fi
}

get_downloaded() {
    local manifest="$_ROOT/download/download.manifest"
    [ -f "$manifest" ] && grep "^${1}|" "$manifest" 2>/dev/null | tail -1 | cut -d'|' -f2 || true
}

get_latest_cached() {
    local manifest="$_ROOT/download/update.manifest"
    [ -f "$manifest" ] && grep "^${1}|" "$manifest" 2>/dev/null | tail -1 | cut -d'|' -f2 || true
}

find_manifest() {
    local name="$1"
    for m in "${REGISTRY[@]}"; do
        [ "$(meta_get "$m" "name")" = "$name" ] && { echo "$m"; return; }
    done
}

get_latest_version() {
    local manifest="$1"
    (
        source "$manifest"
        type get_latest &>/dev/null && get_latest
    )
}

run_upgrade() {
    local manifest="$1"
    local result_file="$TMP_DIR/.forge_result_$$"
    mkdir -p "$TMP_DIR"
    rm -f "$result_file"
    (
        source "$manifest"
        if type upgrade &>/dev/null; then
            upgrade
        fi
    )
    if [ -f "$result_file" ]; then
        cat "$result_file"
        rm -f "$result_file"
    fi
}

# 计算字符串显示宽度（CJK=2, ASCII=1, 忽略 ANSI 颜色码）
_dw() {
    local clean
    clean=$(printf '%b' "$1" | sed $'s/\033\\[[0-9;]*m//g')
    local w=0 c
    for ((i=0; i<${#clean}; i++)); do
        c="${clean:$i:1}"
        case "$c" in
            [a-zA-Z0-9_.\ \-\~/:\(\)]) ((w++)) || true ;;
            *) ((w+=2)) || true ;;
        esac
    done
    echo "$w"
}

# 带 ANSI 颜色的安全填充（基于显示宽度）
_pad() {
    local text="$1" width="$2"
    local vis=$(_dw "$text")
    local pad=$((width - vis))
    [ $pad -lt 0 ] && pad=0
    printf '%b' "$text"
    printf '%'"${pad}"'s' ""
}

print_header() {
    local widths=(20 12 12 10 6)
    echo ""
    local i=0
    for arg in "$@"; do
        _pad "${BOLD}${arg}${NC}" "${widths[$i]:-12}"
        ((i++)) || true
    done
    echo ""
    i=0
    for arg in "$@"; do
        local w=${widths[$i]:-12}
        printf '%.0s─' $(seq 1 $w)
        ((i++)) || true
    done
    echo ""
}
