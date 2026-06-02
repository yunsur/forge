#!/usr/bin/env bash
# 命令: push — 打包并推送到远程服务器

cmd_push() {
    local target="${1:-}"
    local remote_path="${2:-/tmp}"

    if [[ -z "$target" ]]; then
        err "缺少目标服务器"
        echo "  用法: forge push <user@host[:port]> [remote_path]"
        echo "  例:   forge push root@192.168.1.100"
        echo "        forge push root@192.168.1.100:2222 /opt/forge"
        return 1
    fi

    # ── 解析 user@host:port ──────────────────────────────
    local user="root" host port_opt=""

    if [[ "$target" == *@* ]]; then
        user="${target%%@*}"
        host="${target#*@}"
    else
        host="$target"
    fi

    if [[ "$host" =~ :([0-9]+)$ ]]; then
        local port="${BASH_REMATCH[1]}"
        host="${host%:$port}"
        port_opt="$port"
    fi

    _log "推送" "$user@$host → $remote_path"

    # ── 打包 ─────────────────────────────────────────────
    local tarball
    tarball="/tmp/forge_push_$(date +%Y%m%d%H%M%S).tgz"
    (cd "$_ROOT" && cmd_pack "$tarball") || {
        err "打包失败"; return 1
    }

    # ── 传输 ─────────────────────────────────────────────
    _log "传输" "scp → $user@$host:$remote_path/"
    local port_flag=""
    [[ -n "$port_opt" ]] && port_flag="-P $port_opt"

    # shellcheck disable=SC2086
    scp $port_flag "$tarball" "$user@$host:$remote_path/" || {
        err "传输失败"; rm -f "$tarball"; return 1
    }

    rm -f "$tarball"
    ok "传输完成: $user@$host:$remote_path/$(basename "$tarball")"
}
