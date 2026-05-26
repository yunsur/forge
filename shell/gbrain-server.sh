#!/usr/bin/env bash
# ─────────────────────────────────────────────────────────
# GBrain 服务端部署脚本
# 在 GBrain 服务器上运行: bash scripts/gbrain-server.sh
#
# 功能:
#   1. 初始化 GBrain PGLite 本地数据库
#   2. 启动 gbrain serve（监听内网）
#   3. 生成客户端连接命令
# ─────────────────────────────────────────────────────────
set -euo pipefail

FORGE_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
AI_HOME="${AI_HOME:-$FORGE_ROOT/ai}"

R='\033[0;31m' G='\033[0;32m' Y='\033[1;33m' B='\033[0;34m'
NC='\033[0m' BOLD='\033[1m'

_log()  { echo -e "${B}[$1]${NC} $2"; }
ok()    { echo -e "${G}[完成]${NC} $1"; }
warn()  { echo -e "${Y}[注意]${NC} $1" >&2; }
err()   { echo -e "${R}[错误]${NC} $1" >&2; }

# ── 检查 gbrain 是否可用 ──────────────────────────────────

check_gbrain() {
    if ! command -v gbrain &>/dev/null; then
        err "gbrain 未安装"
        echo "  先运行: source env.sh && ./forge install gstack"
        echo "  然后: ~/.claude/skills/gstack-*/bin/gstack-gbrain-install"
        exit 1
    fi
    local ver
    ver=$(gbrain --version 2>/dev/null | head -1)
    ok "gbrain 已安装: $ver"
}

# ── 初始化 PGLite ─────────────────────────────────────────

init_brain() {
    if [ -f "$HOME/.gbrain/config.json" ]; then
        warn "GBrain 已初始化，跳过（如需重置: rm -rf ~/.gbrain && 重新运行）"
        return 0
    fi

    _log "初始化" "GBrain PGLite 本地模式"
    gbrain init --pglite --json
    ok "GBrain 数据库就绪"
}

# ── 获取服务器 IP ─────────────────────────────────────────

get_server_ip() {
    local ip=""
    # macOS
    if command -v ipconfig &>/dev/null; then
        ip=$(ipconfig getifaddr en0 2>/dev/null || ipconfig getifaddr en1 2>/dev/null || true)
    fi
    # Linux
    if [ -z "$ip" ] && command -v hostname &>/dev/null; then
        ip=$(hostname -I 2>/dev/null | awk '{print $1}' || true)
    fi
    # fallback
    if [ -z "$ip" ]; then
        ip=$(ifconfig 2>/dev/null | grep -oE 'inet [0-9.]+' | grep -v '127.0.0.1' | head -1 | awk '{print $2}' || true)
    fi
    echo "${ip:-127.0.0.1}"
}

# ── 启动服务 ──────────────────────────────────────────────

start_server() {
    local port="${1:-3131}"
    local ip
    ip=$(get_server_ip)

    _log "启动" "GBrain 服务"
    echo ""
    echo -e "  ${BOLD}服务地址:${NC} http://${ip}:${port}/mcp"
    echo -e "  ${BOLD}数据库:${NC}   ~/.gbrain/brain.pglite"
    echo ""

    # 生成客户端连接信息
    echo -e "${BOLD}客户端连接命令:${NC}"
    echo ""
    echo "  claude mcp add --scope user --transport http gbrain \\"
    echo "    \"http://${ip}:${port}/mcp\""
    echo ""

    # 写入连接信息文件（方便分发）
    local info_file="$FORGE_ROOT/ai/gbrain-server-info.txt"
    cat > "$info_file" << EOF
# GBrain 服务器信息
# 生成时间: $(date)

服务器地址: http://${ip}:${port}
MCP 端点: http://${ip}:${port}/mcp

# 客户端连接命令:
claude mcp add --scope user --transport http gbrain "http://${ip}:${port}/mcp"

# 环境变量（可选）:
export GBRAIN_SERVER="http://${ip}:${port}"
EOF

    ok "连接信息已写入: $info_file"
    echo ""
    echo -e "${Y}按 Ctrl+C 停止服务${NC}"
    echo ""

    # 启动 gbrain serve
    exec gbrain serve --port "$port" --host 0.0.0.0
}

# ── 后台启动（nohup，不需要 root）─────────────────────────

start_bg() {
    local port="${1:-3131}"
    local ip
    ip=$(get_server_ip)
    local pid_file="$HOME/.gbrain/gbrain.pid"
    local log_file="$HOME/.gbrain/gbrain.log"

    mkdir -p "$HOME/.gbrain"

    # 检查是否已在运行
    if [ -f "$pid_file" ]; then
        local old_pid
        old_pid=$(cat "$pid_file")
        if kill -0 "$old_pid" 2>/dev/null; then
            err "GBrain 已在运行 (PID $old_pid)"
            echo "  停止: bash scripts/gbrain-server.sh stop"
            echo "  日志: tail -f $log_file"
            return 1
        fi
        rm -f "$pid_file"
    fi

    _log "后台启动" "GBrain 服务 (port $port)"

    nohup gbrain serve --port "$port" --host 0.0.0.0 \
        > "$log_file" 2>&1 &
    local pid=$!
    echo "$pid" > "$pid_file"

    # 等 2 秒确认启动
    sleep 2
    if kill -0 "$pid" 2>/dev/null; then
        ok "GBrain 已启动 (PID $pid)"
    else
        err "启动失败，查看日志: $log_file"
        return 1
    fi

    echo ""
    echo -e "  ${BOLD}服务地址:${NC} http://${ip}:${port}/mcp"
    echo -e "  ${BOLD}PID 文件:${NC} $pid_file"
    echo -e "  ${BOLD}日志文件:${NC} $log_file"
    echo ""
    echo "  停止: bash scripts/gbrain-server.sh stop"
    echo "  日志: tail -f $log_file"

    # 写入连接信息
    local info_file="$FORGE_ROOT/ai/gbrain-server-info.txt"
    cat > "$info_file" << EOF
# GBrain 服务器信息
# 生成时间: $(date)

服务器地址: http://${ip}:${port}
MCP 端点: http://${ip}:${port}/mcp
PID: $pid

# 客户端连接命令:
claude mcp add --scope user --transport http gbrain "http://${ip}:${port}/mcp"
EOF
}

# ── 停止后台服务 ──────────────────────────────────────────

stop_server() {
    local pid_file="$HOME/.gbrain/gbrain.pid"

    if [ ! -f "$pid_file" ]; then
        warn "PID 文件不存在，GBrain 可能未在运行"
        # 尝试通过进程查找
        local pid
        pid=$(pgrep -f "gbrain serve" 2>/dev/null || true)
        if [ -n "$pid" ]; then
            echo "  发现进程: $pid"
            kill "$pid" 2>/dev/null && ok "已停止 GBrain (PID $pid)"
        else
            echo "  未发现 gbrain serve 进程"
        fi
        return 0
    fi

    local pid
    pid=$(cat "$pid_file")
    if kill -0 "$pid" 2>/dev/null; then
        kill "$pid"
        rm -f "$pid_file"
        ok "GBrain 已停止 (PID $pid)"
    else
        warn "进程 $pid 已不存在"
        rm -f "$pid_file"
    fi
}

# ── 查看状态 ──────────────────────────────────────────────

status_server() {
    local pid_file="$HOME/.gbrain/gbrain.pid"
    local log_file="$HOME/.gbrain/gbrain.log"

    if [ -f "$pid_file" ]; then
        local pid
        pid=$(cat "$pid_file")
        if kill -0 "$pid" 2>/dev/null; then
            ok "GBrain 正在运行 (PID $pid)"
            echo "  日志: tail -f $log_file"
            # 显示最后几行日志
            if [ -f "$log_file" ]; then
                echo ""
                echo "  最近日志:"
                tail -3 "$log_file" | sed 's/^/    /'
            fi
        else
            warn "PID 文件存在但进程已死 (PID $pid)"
            echo "  清理: rm $pid_file"
            echo "  重启: bash scripts/gbrain-server.sh start-bg"
        fi
    else
        # 尝试通过进程查找
        local pid
        pid=$(pgrep -f "gbrain serve" 2>/dev/null || true)
        if [ -n "$pid" ]; then
            warn "GBrain 正在运行 (PID $pid)，但无 PID 文件"
        else
            echo "GBrain 未在运行"
        fi
    fi
}

# ── 用户级 systemd（不需要 root）──────────────────────────

generate_user_systemd() {
    local port="${1:-3131}"
    local gbrain_bin
    gbrain_bin=$(command -v gbrain)

    cat << EOF
# 用户级 systemd 服务（不需要 root）
#
# 安装步骤:
#   mkdir -p ~/.config/systemd/user
#   bash scripts/gbrain-server.sh user-systemd > ~/.config/systemd/user/gbrain.service
#   systemctl --user daemon-reload
#   systemctl --user start gbrain
#   systemctl --user enable gbrain
#
# 如果需要开机自启（即使未登录）:
#   sudo loginctl enable-linger \$(whoami)
#
# 常用命令:
#   systemctl --user status gbrain
#   systemctl --user stop gbrain
#   journalctl --user -u gbrain -f

[Unit]
Description=GBrain Knowledge Server
After=network.target

[Service]
Type=simple
ExecStart=${gbrain_bin} serve --port ${port} --host 0.0.0.0
Restart=always
RestartSec=5
Environment=HOME=${HOME}

[Install]
WantedBy=default.target
EOF
}

# ── 系统级 systemd（需要 root）────────────────────────────

generate_systemd() {
    local port="${1:-3131}"
    local gbrain_bin
    gbrain_bin=$(command -v gbrain)
    local user
    user=$(whoami)

    cat << EOF
# /etc/systemd/system/gbrain.service（需要 root）
# 安装: sudo cp gbrain.service /etc/systemd/system/ && sudo systemctl daemon-reload
# 启动: sudo systemctl start gbrain && sudo systemctl enable gbrain

[Unit]
Description=GBrain Knowledge Server
After=network.target

[Service]
Type=simple
User=${user}
ExecStart=${gbrain_bin} serve --port ${port} --host 0.0.0.0
Restart=always
RestartSec=5
Environment=HOME=${HOME}

[Install]
WantedBy=multi-user.target
EOF
}

# ── 主入口 ────────────────────────────────────────────────

case "${1:-}" in
    init)
        check_gbrain
        init_brain
        ;;
    start)
        check_gbrain
        start_server "${2:-3131}"
        ;;
    start-bg)
        check_gbrain
        start_bg "${2:-3131}"
        ;;
    stop)
        stop_server
        ;;
    status)
        status_server
        ;;
    restart)
        stop_server
        sleep 1
        check_gbrain
        start_bg "${2:-3131}"
        ;;
    logs)
        local log_file="$HOME/.gbrain/gbrain.log"
        if [ -f "$log_file" ]; then
            tail -f "$log_file"
        else
            warn "日志文件不存在: $log_file"
        fi
        ;;
    systemd)
        generate_systemd "${2:-3131}"
        ;;
    user-systemd)
        generate_user_systemd "${2:-3131}"
        ;;
    ip)
        get_server_ip
        ;;
    info)
        local_ip=$(get_server_ip)
        echo "服务器 IP: $local_ip"
        echo "MCP 端点: http://${local_ip}:3131/mcp"
        echo ""
        echo "客户端连接:"
        echo "  claude mcp add --scope user --transport http gbrain \"http://${local_ip}:3131/mcp\""
        ;;
    *)
        echo -e "\n${BOLD}GBrain 服务端部署${NC}\n"
        echo "用法: bash scripts/gbrain-server.sh <子命令>"
        echo ""
        echo "  init              初始化 GBrain 数据库"
        echo "  start [port]      前台启动（Ctrl+C 停止）"
        echo "  start-bg [port]   后台启动（nohup，不需要 root）"
        echo "  stop              停止后台服务"
        echo "  status            查看运行状态"
        echo "  restart [port]    重启后台服务"
        echo "  logs              查看实时日志"
        echo "  user-systemd      生成用户级 systemd 服务（不需要 root）"
        echo "  systemd           生成系统级 systemd 服务（需要 root）"
        echo "  ip                显示服务器 IP"
        echo "  info              显示完整连接信息"
        echo ""
        echo "部署流程（普通用户）:"
        echo "  1. bash scripts/gbrain-server.sh init"
        echo "  2. bash scripts/gbrain-server.sh start-bg"
        echo "  3. 客户端: claude mcp add --scope user --transport http gbrain \"http://<IP>:3131/mcp\""
        echo ""
        echo "开机自启（二选一）:"
        echo "  方案A: bash scripts/gbrain-server.sh user-systemd > ~/.config/systemd/user/gbrain.service"
        echo "         systemctl --user enable gbrain"
        echo "         sudo loginctl enable-linger \$(whoami)"
        echo "  方案B: 将 start-bg 加入 crontab: @reboot bash /path/to/scripts/gbrain-server.sh start-bg"
        ;;
esac
