#!/usr/bin/env bash
# 命令: npm — 封装 npm，安装后自动链接全局二进制到 ai/bin/

cmd_npm() {
    local npm_bin="$AI_HOME/tools/node/bin/npm"
    if [ ! -f "$npm_bin" ]; then
        err "node 未安装，请先运行: forge install node"
        return 1
    fi

    "$npm_bin" "$@"
    local ret=$?

    # 安装类操作：自动链接新全局二进制
    local args="$*"
    if [[ "$args" == *"install"* ]] || [[ "$args" == *" i "* ]] || [[ "$args" == *"add"* ]]; then
        if [[ "$args" == *"-g"* ]] || [[ "$args" == *"--global"* ]]; then
            _link_npm_globals
        fi
    fi

    return $ret
}

_link_npm_globals() {
    local npm_global_bin
    npm_global_bin=$("$AI_HOME/tools/node/bin/npm" prefix -g 2>/dev/null)/bin || return 0
    [ -d "$npm_global_bin" ] || return 0

    local linked=0
    for f in "$npm_global_bin"/*; do
        [ -f "$f" ] || continue
        local name
        name=$(basename "$f")
        # 跳过已存在的工具（node/npm/npx 等）
        [ -L "$AI_HOME/bin/$name" ] && continue
        link_binary "$f" && ((linked++)) || true
    done
    [ $linked -gt 0 ] && ok "npm globals: ${linked} 个二进制 → ai/bin/"
}
