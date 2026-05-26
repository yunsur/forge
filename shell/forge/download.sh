#!/usr/bin/env bash
# 命令: download

# download 专用：覆盖 fetch/fetch_to/link_binary，只下载不安装
_fetch_for_download() {
    local name="$1" url="$2" format="$3" mode="${4:-}" binary_name="${5:-}"
    local filename
    filename=$(basename "$url" | sed 's/?.*//')
    local dest="$_ROOT/download"
    mkdir -p "$dest"
    # 文件名去重
    if [ -f "$dest/$filename" ]; then
        local i=1 base="$filename"
        while [ -f "$dest/${base}.${i}" ]; do ((i++)); done
        filename="${base}.${i}"
    fi
    _log "下载" "$name → $filename"
    curl $(_curl_opts) -fSL -o "$dest/$filename" "$url"
    # 更新 install manifest（name|version|filename，去除旧条目）
    local mf="$_ROOT/download/download.manifest"
    [ -f "$mf" ] && sed -i.bak "/^${name}|/d" "$mf" && rm -f "$mf.bak"
    echo "${name}|${_DOWNLOAD_VERSION:-?}|${filename}" >> "$mf"
    ok "$name"
}

_fetch_to_for_download() {
    local dest="$1" url="$2" format="$3" mode="${4:-}" binary_name="${5:-}"
    local filename
    filename=$(basename "$url" | sed 's/?.*//')
    local dl_dest="$_ROOT/download"
    mkdir -p "$dl_dest"
    if [ -f "$dl_dest/$filename" ]; then
        local i=1 base="$filename"
        while [ -f "$dl_dest/${base}.${i}" ]; do ((i++)); done
        filename="${base}.${i}"
    fi
    curl $(_curl_opts) -fSL -o "$dl_dest/$filename" "$url"
    echo "${_DOWNLOAD_NAME:-_}|${filename}" >> "$_ROOT/download/download.manifest"
}

cmd_download() {
    load_registry
    local targets=("$@")

    if [ ${#targets[@]} -eq 0 ]; then
        targets=()
        for manifest in "${REGISTRY[@]}"; do
            local name
            name=$(meta_get "$manifest" "name")
            targets+=("$name")
        done
    fi

    [ ${#targets[@]} -eq 0 ] && { echo "没有可下载的工具。"; return; }

    # 准备下载目录和 manifest
    mkdir -p "$_ROOT/download"

    echo ""
    local ok=0 fail=0

    for tool in "${targets[@]}"; do
        local manifest
        manifest=$(find_manifest "$tool")
        if [ -z "$manifest" ]; then
            echo -e "${R}[错误]${NC} 未知工具: $tool"
            ((fail++)) || true
            continue
        fi

        local latest
        latest=$(get_latest_version "$manifest")
        [ -z "$latest" ] && latest="?"

        echo -e "${B}[下载]${NC} ${BOLD}${tool}${NC}  ${G}${latest}${NC}"

        # 覆盖函数：只下载不安装
        _DOWNLOAD_NAME="$tool"
        _DOWNLOAD_VERSION="$latest"
        if (
            source "$manifest"
            fetch() { _fetch_for_download "$@"; }
            fetch_to() { _fetch_to_for_download "$@"; }
            link_binary() { :; }
            type upgrade &>/dev/null && upgrade
        ); then
            set_installed "$tool" "$latest"
            echo -e "  ${G}✓${NC} ${tool} ${latest}"
            ((ok++)) || true
        else
            echo -e "  ${R}✗${NC} ${tool} 失败"
            ((fail++)) || true
        fi
    done

    echo -e "\n${BOLD}完成:${NC} ${G}${ok} 成功${NC}  ${R}${fail} 失败${NC}"
    echo -e "${D}文件保存在 download/，执行 init.sh 完成安装${NC}\n"
}
