#!/usr/bin/env bash
# 命令: mcp

cmd_mcp() {
    local subcmd="${1:-}"
    shift 2>/dev/null || true

    case "$subcmd" in
        install) _mcp_install "$@" ;;
        remove|rm) shift; _mcp_remove "$@" ;;
        list|ls) _mcp_list ;;
        *)       _mcp_list ;;
    esac
}

_mcp_install() {
    _log "mcp" "安装 MCP server 包"

    if ! command -v npx &>/dev/null; then
        err "npx 不可用（需要 node/npm）"
        return 1
    fi

    local mcp_file="$ROOT_DIR/config/claude/mcp.json"
    if [ ! -f "$mcp_file" ]; then
        warn "未找到 $mcp_file"
        return 1
    fi

    local ok=0 fail=0
    while IFS= read -r sname; do
        local pkg
        pkg=$(python3 -c "
import json
d=json.load(open('$mcp_file'))
srv=d['mcpServers']['$sname']
for a in srv.get('args',[]):
    if a not in ('-y','--yes') and not a.startswith('-'):
        print(a); exit()
" 2>/dev/null || true)

        if [ -z "$pkg" ]; then
            warn "$sname: 无法提取包名"
            ((fail++)) || true
            continue
        fi

        echo -e "  ${B}安装${NC} $sname ($pkg)"
        if npx -y "$pkg" --version &>/dev/null || npm install -g "$pkg" &>/dev/null; then
            ok "  $sname"
            ((ok++)) || true
        else
            warn "  $sname 安装失败"
            ((fail++)) || true
        fi
    done < <(python3 -c "
import json
d=json.load(open('$mcp_file'))
for k in d['mcpServers']: print(k)
" 2>/dev/null || true)

    echo ""
    ok "MCP: ${ok} 成功  ${fail} 失败"
}

_mcp_list() {
    _log "mcp" "已配置的 MCP server"

    local mcp_file="$ROOT_DIR/config/claude/mcp.json"
    if [ ! -f "$mcp_file" ]; then
        echo "  (无配置)"
        return
    fi

    local count=0
    while IFS= read -r line; do
        local sname="${line%%|*}"
        local cmd="${line#*|}"
        printf "  %-20s %s\n" "$sname" "$cmd"
        ((count++)) || true
    done < <(python3 -c "
import json
d=json.load(open('$mcp_file'))
for k,v in d['mcpServers'].items():
    print(k+'|'+v.get('command','?')+' '+' '.join(v.get('args',[])))
" 2>/dev/null || true)

    [ $count -eq 0 ] && echo "  (无配置)"
    echo ""
}

_mcp_remove() {
    local sname="${1:-}"
    if [ -z "$sname" ]; then
        err "用法: forge mcp remove <server-name>"
        return 1
    fi

    local mcp_file="$ROOT_DIR/config/claude/mcp.json"
    if [ ! -f "$mcp_file" ]; then
        warn "未找到 $mcp_file"
        return 1
    fi

    # 检查是否存在
    if ! python3 -c "
import json,sys
d=json.load(open('$mcp_file'))
sys.exit(0 if '$sname' in d.get('mcpServers',{}) else 1)
" 2>/dev/null; then
        warn "$sname: 未在配置中找到"
        return 1
    fi

    # 从 config/claude/mcp.json 移除
    python3 -c "
import json
f='$mcp_file'
d=json.load(open(f))
d['mcpServers'].pop('$sname',None)
with open(f,'w') as fh: json.dump(d,fh,indent=2)
print('$sname 已移除')
" && ok "$sname 已从 mcp.json 移除" || { err "移除失败"; return 1; }

    # 同步移除 ~/.claude/mcp.json 中的对应条目
    local deployed="$HOME/.claude/mcp.json"
    if [ -f "$deployed" ]; then
        python3 -c "
import json
f='$deployed'
d=json.load(open(f))
d.get('mcpServers',{}).pop('$sname',None)
with open(f,'w') as fh: json.dump(d,fh,indent=2)
" 2>/dev/null && ok "$sname 已从 ~/.claude/mcp.json 移除"
    fi
}
