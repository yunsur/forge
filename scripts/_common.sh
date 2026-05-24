#!/usr/bin/env bash
# 公共函数库（被 manifest 和 forge source）

_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
AI_HOME="${AI_HOME:-$_ROOT/ai}"
TOOLS_DIR="$AI_HOME/tools"
RUNTIMES_DIR="$AI_HOME/runtimes"
TMP_DIR="$AI_HOME/tmp/.download"
mkdir -p "$TOOLS_DIR" "$RUNTIMES_DIR" "$TMP_DIR"

OS="${OS:-linux}"
ARCH="${ARCH:-amd64}"

# 颜色
_log()  { echo -e "\033[0;34m[$1]\033[0m $2"; }
ok()    { echo -e "\033[0;32m[完成]\033[0m $1"; }
warn()  { echo -e "\033[1;33m[注意]\033[0m $1" >&2; }
err()   { echo -e "\033[0;31m[错误]\033[0m $1" >&2; }

# curl 选项（支持代理和 token）
_curl_opts() {
    local opts=(-fsSL --connect-timeout 10 --max-time 30)
    # 代理
    [ -n "${https_proxy:-${HTTPS_PROXY:-}}" ] && opts+=(--proxy "${https_proxy:-$HTTPS_PROXY}")
    [ -n "${http_proxy:-${HTTP_PROXY:-}}" ] && opts+=(--proxy "${http_proxy:-$HTTP_PROXY}")
    # GitHub token（避免限速）
    [ -n "${GITHUB_TOKEN:-}" ] && opts+=(-H "Authorization: Bearer $GITHUB_TOKEN")
    echo "${opts[@]}"
}

# GitHub API: 获取最新 release tag（返回原始 tag，各 manifest 自行处理前缀）
github_latest() {
    local repo="$1" version=""

    # 方式1: GitHub API
    version=$(curl $(_curl_opts) "https://api.github.com/repos/${repo}/releases/latest" 2>/dev/null \
        | grep '"tag_name"' | head -1 \
        | sed -E 's/.*"tag_name"[[:space:]]*:[[:space:]]*"([^"]+)".*/\1/' || true)

    # 方式2: API 失败，从 HTML 页面解析
    if [ -z "$version" ]; then
        version=$(curl $(_curl_opts) "https://github.com/${repo}/releases/latest" 2>/dev/null \
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
    mkdir -p "$dest"
    curl -fSL -o "$tmp" "$url"
    _extract "$tmp" "$dest" "$format" "$mode" "$binary_name"
    rm -f "$tmp"
    ok "$name"
}

# 下载 + 解压到指定目录
fetch_to() {
    local dest="$1" url="$2" format="$3" mode="${4:-}" binary_name="${5:-}"
    mkdir -p "$dest"
    local tmp="$TMP_DIR/_fetch_$$"
    curl -fSL -o "$tmp" "$url"
    _extract "$tmp" "$dest" "$format" "$mode" "$binary_name"
    rm -f "$tmp"
}

_extract() {
    local tmp="$1" dest="$2" format="$3" mode="$4" binary_name="$5"
    case "$format" in
        tar.gz|tgz)
            case "$mode" in
                strip1) tar -xzf "$tmp" -C "$dest" --strip-components=1 ;;
                flat)   tar -xzf "$tmp" -C "$dest" ;;
                flat-binary)
                    tar -xzf "$tmp" -C "$dest"
                    local bin
                    bin=$(find "$dest" -maxdepth 1 -type f -perm +111 -name "${binary_name}" | head -1)
                    [ -n "$bin" ] && mv "$bin" "$dest/$binary_name" && \
                        find "$dest" -mindepth 1 -maxdepth 1 ! -name "$binary_name" -exec rm -rf {} + 2>/dev/null
                    chmod +x "$dest/$binary_name"
                    ;;
                *) tar -xzf "$tmp" -C "$dest" ;;
            esac
            ;;
        zip)
            unzip -q -o "$tmp" -d "$dest"
            if [ "$mode" = "flat-binary" ] && [ -n "$binary_name" ]; then
                local bin
                bin=$(find "$dest" -type f -name "$binary_name" | head -1)
                [ -n "$bin" ] && mv "$bin" "$dest/$binary_name" && \
                    find "$dest" -mindepth 1 ! -name "$binary_name" -exec rm -rf {} + 2>/dev/null
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
