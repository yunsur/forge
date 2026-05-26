#!/usr/bin/env bash
# 命令: pack

cmd_pack() {
    local out="${1:-forge_$(date +%Y%m%d%H).tgz}"
    echo -e "${B}[打包]${NC} $out"
    local staging="$AI_HOME/tmp/.pack"
    rm -rf "$staging"
    local dest="$staging/forge"
    mkdir -p "$dest/ai"
    # 复制 download/（下载的压缩包）
    if [ -d "$_ROOT/download" ]; then
        cp -r "$_ROOT/download" "$dest/"
    fi
    # 项目文件（shell/ 已包含 env.sh 和 forge 模块）
    for d in config skills mcp shell registry; do
        [ -d "$_ROOT/$d" ] && cp -r "$_ROOT/$d" "$dest/"
    done
    [ -f "$_ROOT/forge" ] && cp "$_ROOT/forge" "$dest/"
    # 去除 macOS 特殊文件
    find "$staging" -name '.DS_Store' -delete 2>/dev/null
    find "$staging" -name '._*' -delete 2>/dev/null
    # 打包（只含 forge/ 目录）
    tar -czf "$out" -C "$staging" forge/
    rm -rf "$staging"
    local size
    size=$(du -h "$out" | cut -f1)
    echo -e "${G}[完成]${NC} $out ($size)"
    echo -e "${D}目标机器: tar xzf $(basename "$out") && cd forge && ./forge init${NC}"
}
