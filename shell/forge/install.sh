#!/usr/bin/env bash
# 命令: install — 安装环境无关的工具
#
# 两阶段安装:
#   forge install   → 安装所有无需运行时依赖的工具（解压+git clone+字体+链接）
#   forge init      → 安装需要环境依赖的工具（pyenv-virtualenv、python、openspec）+ 配置
#
# 子命令:
#   forge install              全量安装环境无关工具
#   forge install <tool...>    安装指定工具

# 需要环境依赖的工具列表（跳过，留给 init 处理）
ENV_DEPS_TOOLS=(pyenv-virtualenv python openspec speckit)

# 检查工具是否在环境依赖列表中
_is_env_dep() {
    local tool="$1"
    for dep in "${ENV_DEPS_TOOLS[@]}"; do
        [ "$tool" = "$dep" ] && return 0
    done
    return 1
}

# ── install tools ────────────────────────────────────────────

_install_tools() {
    local manifest_file="$ROOT_DIR/download/download.manifest"
    local downloads="$ROOT_DIR/download"

    mkdir -p "$AI_HOME/tools" "$AI_HOME/runtimes" "$AI_HOME/bin"

    # 从 download.manifest 解压
    if [ -f "$manifest_file" ]; then
        _log "install" "安装工具（从 download.manifest）"

        declare -A TOOL_FILES
        declare -a TOOL_ORDER
        while IFS='|' read -r tname tver tfile; do
            [ -z "$tname" ] && continue
            if [ -z "$tfile" ]; then
                tfile="$tver"
                tver=""
            fi
            # 跳过需要环境依赖的工具
            if _is_env_dep "$tname"; then
                continue
            fi
            if [ -z "${TOOL_FILES[$tname]:-}" ]; then
                TOOL_ORDER+=("$tname")
                TOOL_FILES[$tname]="$tfile"
            else
                TOOL_FILES[$tname]="${TOOL_FILES[$tname]} $tfile"
            fi
        done < "$manifest_file"

        local installed=0 skipped=0 failed=0

        for tool in "${TOOL_ORDER[@]}"; do
            local files="${TOOL_FILES[$tool]}"

            # 增量：目录存在且版本一致则跳过
            if [ -d "$AI_HOME/tools/$tool" ] || [ -d "$AI_HOME/runtimes/$tool" ]; then
                local latest_file=""
                for f in $files; do
                    [ -f "$downloads/$f" ] && latest_file="$f"
                done
                if [ -n "$latest_file" ]; then
                    local dl_ver
                    dl_ver=$(grep "^${tool}|" "$manifest_file" 2>/dev/null | tail -1 | cut -d'|' -f2)
                    local installed_ver
                    installed_ver=$(get_installed "$tool")
                    local dl_norm="${dl_ver#v}" inst_norm="${installed_ver#v}"
                    if [ -n "$installed_ver" ] && [ "$dl_norm" = "$inst_norm" ]; then
                        ((skipped++)) || true
                        continue
                    fi
                fi
            fi

            local mfile=""
            for m in "$REGISTRY_DIR"/*.sh; do
                [ -f "$m" ] || continue
                if grep -q "^# @name: $tool$" "$m" 2>/dev/null; then
                    mfile="$m"
                    break
                fi
            done

            if [ -z "$mfile" ]; then
                warn "未找到 $tool 的 registry manifest，跳过"
                ((skipped++)) || true
                continue
            fi

            if grep -q '^install_from()' "$mfile" 2>/dev/null; then
                for fname in $files; do
                    local fpath="$downloads/$fname"
                    if [ -f "$fpath" ]; then
                        if (
                            source "$mfile"
                            install_from "$fpath"
                        ); then
                            ((installed++)) || true
                        else
                            err "$tool 安装失败: $fname"
                            ((failed++)) || true
                        fi
                    else
                        warn "$tool 文件不存在: $fpath"
                        ((failed++)) || true
                    fi
                done
            else
                warn "$tool 无 install_from()，跳过"
                ((skipped++)) || true
            fi
        done

        ok "安装: ${installed} 成功  ${skipped} 跳过  ${failed} 失败"
    else
        if [ ! -d "$AI_HOME/tools/gstack" ] && [ ! -d "$AI_HOME/tools/superpowers" ]; then
            _log "install" "未发现 download.manifest，跳过工具安装"
        fi
    fi

    # git 工具（gstack、superpowers）从 download/ 复制
    for git_tool in gstack superpowers; do
        if [ ! -d "$AI_HOME/tools/$git_tool" ]; then
            local src="$downloads/$git_tool"
            if [ -d "$src" ]; then
                cp -r "$src" "$AI_HOME/tools/$git_tool"
                ok "$git_tool (from download/)"
            else
                warn "$git_tool 未在 download/ 中找到，跳过"
            fi
        fi
    done

    # 字体文件从 download/ 解压
    if [ -d "$downloads/jetbrains-mono-nf" ]; then
        local font_file
        font_file=$(find "$downloads" -maxdepth 1 -name "JetBrainsMono*.zip" | head -1)
        if [ -n "$font_file" ]; then
            local mfile=""
            for m in "$REGISTRY_DIR"/*.sh; do
                [ -f "$m" ] || continue
                if grep -q "^# @name: jetbrains-mono-nf$" "$m" 2>/dev/null; then
                    mfile="$m"
                    break
                fi
            done
            if [ -n "$mfile" ]; then
                (
                    source "$mfile"
                    install_from "$font_file"
                )
            fi
        fi
    fi
}

# ── 主入口 ──────────────────────────────────────────────────

cmd_install() {
    # 开发环境安全防护
    if is_forge_dev; then
        err "当前为开发环境（forge 仓库内），禁止执行 install"
        echo -e "  ${D}如需强制执行: FORGE_SKIP_DEV_CHECK=1 forge install${NC}"
        return 1
    fi

    load_registry

    # 支持指定工具列表
    local targets=()
    for arg in "$@"; do
        case "$arg" in
            --force|-f) ;;  # TODO: 支持强制重装
            *) targets+=("$arg") ;;
        esac
    done

    if [ ${#targets[@]} -gt 0 ]; then
        # 安装指定工具
        mkdir -p "$AI_HOME/tools" "$AI_HOME/runtimes" "$AI_HOME/bin"
        local downloads="$ROOT_DIR/download"
        for tool in "${targets[@]}"; do
            if _is_env_dep "$tool"; then
                warn "$tool 需要环境依赖，请使用: forge init tools"
                continue
            fi

            # git 工具：从 download/ 复制
            case "$tool" in
                gstack|superpowers)
                    if [ ! -d "$AI_HOME/tools/$tool" ] && [ -d "$downloads/$tool" ]; then
                        cp -r "$downloads/$tool" "$AI_HOME/tools/$tool"
                        ok "$tool (from download/)"
                    elif [ -d "$AI_HOME/tools/$tool" ]; then
                        ok "$tool (已安装)"
                    else
                        warn "$tool 未在 download/ 中找到，请先运行: forge download $tool"
                    fi
                    continue
                    ;;
            esac

            # 字体：特殊处理
            if [ "$tool" = "jetbrains-mono-nf" ]; then
                local font_file
                font_file=$(find "$downloads" -maxdepth 1 -name "JetBrainsMono*.zip" | head -1)
                if [ -n "$font_file" ]; then
                    local mfile=""
                    for m in "$REGISTRY_DIR"/*.sh; do
                        [ -f "$m" ] || continue
                        if grep -q "^# @name: jetbrains-mono-nf$" "$m" 2>/dev/null; then
                            mfile="$m"
                            break
                        fi
                    done
                    if [ -n "$mfile" ]; then
                        (
                            source "$mfile"
                            install_from "$font_file"
                        )
                        ok "$tool"
                    fi
                else
                    warn "$tool 未在 download/ 中找到，请先运行: forge download $tool"
                fi
                continue
            fi

            # 标准工具：从 download.manifest 查找
            local mfile=""
            for m in "$REGISTRY_DIR"/*.sh; do
                [ -f "$m" ] || continue
                if grep -q "^# @name: $tool$" "$m" 2>/dev/null; then
                    mfile="$m"
                    break
                fi
            done

            if [ -z "$mfile" ]; then
                err "未知工具: $tool"
                continue
            fi

            # 查找 download.manifest 中的所有文件
            local files=""
            if [ -f "$downloads/download.manifest" ]; then
                while IFS='|' read -r tname tver tfile; do
                    [ -z "$tname" ] && continue
                    [ "$tname" != "$tool" ] && continue
                    if [ -z "$tfile" ]; then
                        files="${files:+$files }$tver"
                    else
                        files="${files:+$files }$tfile"
                    fi
                done < "$downloads/download.manifest"
            fi

            if [ -z "$files" ]; then
                # fallback: 查找 download/ 中匹配的文件
                files=$(find "$downloads" -maxdepth 1 -name "*${tool}*" -not -name "*.manifest" -not -name "*.tmp" -type f | head -1)
                [ -n "$files" ] && files=$(basename "$files")
            fi

            if [ -z "$files" ]; then
                warn "$tool 未下载，请先运行: forge download $tool"
                continue
            fi

            for fname in $files; do
                local fpath="$downloads/$fname"
                if [ -f "$fpath" ]; then
                    if (
                        source "$mfile"
                        install_from "$fpath"
                    ); then
                        ok "$tool"
                    else
                        err "$tool 安装失败"
                    fi
                fi
            done
        done

        _init_bins
    else
        # 全量安装
        _install_tools
        _init_bins
    fi
}
