#!/usr/bin/env bash
# 命令: new

cmd_new() {
    local name="$1"
    [ -z "$name" ] && { echo "用法: forge new <tool-name>" >&2; exit 1; }

    local dest="$REGISTRY_DIR/${name}.sh"
    [ -f "$dest" ] && { echo "manifest 已存在: $dest" >&2; exit 1; }

    cat > "$dest" << 'TEMPLATE'
#!/usr/bin/env bash
_SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$_SCRIPT_DIR/../shell/forge/common.sh"

# @name: TOOL_NAME
# @repo: OWNER/REPO

get_latest() {
    github_latest "OWNER/REPO"
}

upgrade() {
    local latest; latest=$(get_latest)
    [ -z "$latest" ] && { err "无法获取最新版本"; exit 1; }
    # TODO: 下载逻辑
    fetch "TOOL_NAME" "https://github.com/OWNER/REPO/releases/download/v${latest}/..." "tar.gz" "strip1"
}
TEMPLATE

    sed -i.bak "s/TOOL_NAME/$name/g" "$dest"
    rm -f "$dest.bak"
    chmod +x "$dest"
    echo "已生成: $dest"
    echo "请编辑 @repo 和 upgrade 函数"
}
