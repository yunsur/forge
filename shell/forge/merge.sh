#!/usr/bin/env bash
# 命令: merge

cmd_merge() {
    local target="${1:-}"
    local archive="${2:-}"

    if [ -z "$target" ]; then
        echo -e "${Y}用法:${NC} forge merge config <archive.tgz>"
        exit 1
    fi

    case "$target" in
        config)
            _merge_config "$archive"
            ;;
        *)
            echo -e "${R}[错误]${NC} 未知的合并目标: $target"
            echo -e "${Y}可用目标:${NC} config"
            exit 1
            ;;
    esac
}

_merge_config() {
    local archive="${1:-}"

    if [ -z "$archive" ]; then
        # 查找最新的 config 包
        archive=$(ls -t forge_config_*.tgz 2>/dev/null | head -1)
        if [ -z "$archive" ]; then
            echo -e "${R}[错误]${NC} 未找到配置包，请指定文件"
            exit 1
        fi
        echo -e "${D}使用最新配置包: $archive${NC}"
    fi

    if [ ! -f "$archive" ]; then
        echo -e "${R}[错误]${NC} 文件不存在: $archive"
        exit 1
    fi

    echo -e "${B}[合并配置]${NC} $archive"

    local staging
    staging=$(mktemp -d)

    # 解压配置包
    tar -xzf "$archive" -C "$staging"

    local src="$staging/forge"

    # 验证包结构
    if [ ! -d "$src/config" ] || [ ! -f "$src/forge" ]; then
        echo -e "${R}[错误]${NC} 无效的配置包格式"
        rm -rf "$staging"
        exit 1
    fi

    echo -e "${D}备份当前配置...${NC}"
    local backup="forge_backup_$(date +%Y%m%d%H%M%S)"
    mkdir -p "$backup"
    [ -d "$_ROOT/config" ] && cp -r "$_ROOT/config" "$backup/"

    echo -e "${D}合并配置文件...${NC}"
    # 合并 config 目录（递归复制，覆盖同名文件）
    if [ -d "$src/config" ]; then
        cp -r "$src/config"/* "$_ROOT/config/" 2>/dev/null || \
            cp -r "$src/config" "$_ROOT/"
    fi

    echo -e "${D}更新 forge 命令...${NC}"
    if [ -f "$src/forge" ]; then
        cp "$src/forge" "$_ROOT/forge"
        chmod +x "$_ROOT/forge"
    fi

    # 清理
    rm -rf "$staging"

    echo -e "${G}[完成]${NC} 配置已合并"
    echo -e "${D}备份位置: $backup${NC}"
    echo -e "${D}如需回滚: cp -r $backup/config $_ROOT/${NC}"
}
