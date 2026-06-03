#!/usr/bin/env bash
# 命令: install — 安装环境无关的工具
#
# 两阶段安装:
#   forge install   → 安装所有无需运行时依赖的工具（解压+git clone+字体+链接）
#   forge init      → 安装需要环境依赖的工具（pyenv-virtualenv、python、speckit）+ 配置
#
# 子命令:
#   forge install              全量安装环境无关工具
#   forge install <tool...>    安装指定工具

# 需要环境依赖的工具列表（跳过，留给 init 处理）
ENV_DEPS_TOOLS=(pyenv-virtualenv python speckit)

# 默认不安装的工具（需手动指定，如 forge install rust）
OPTIONAL_TOOLS=(rust go)

# 检查工具是否在环境依赖列表中
_is_env_dep() {
    local tool="$1"
    for dep in "${ENV_DEPS_TOOLS[@]}"; do
        [ "$tool" = "$dep" ] && return 0
    done
    return 1
}

# 检查工具是否为可选工具（全量安装时跳过）
_is_optional() {
    local tool="$1"
    for opt in "${OPTIONAL_TOOLS[@]}"; do
        [ "$tool" = "$opt" ] && return 0
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

        # 收集待处理的工具列表（跳过环境依赖）
        local tools=()
        while IFS='|' read -r tname _ _; do
            [ -z "$tname" ] && continue
            if _is_env_dep "$tname"; then
                continue
            fi
            # 全量安装时跳过可选工具
            if _is_optional "$tname"; then
                continue
            fi
            # 去重
            local found=0
            for t in "${tools[@]}"; do
                [ "$t" = "$tname" ] && found=1 && break
            done
            [ "$found" -eq 0 ] && tools+=("$tname")
        done < "$manifest_file"

        local installed=0 skipped=0 failed=0

        # 并行安装：使用 xargs -P 最大化并发
        local parallel_count
        parallel_count=$(sysctl -n hw.ncpu 2>/dev/null || nproc 2>/dev/null || echo 4)
        # 限制最大并行数，避免资源竞争
        [ "$parallel_count" -gt 8 ] && parallel_count=8

        if [ ${#tools[@]} -gt 0 ]; then
            local result_file
            mkdir -p "$TMP_DIR"
            result_file=$(mktemp "${TMP_DIR}/.install_result_XXXXXX")

            # 使用 xargs 并行执行
            printf '%s\n' "${tools[@]}" | \
                xargs -P "$parallel_count" -I {} bash -c '
                    source "'"$ROOT_DIR"'/shell/forge/common.sh"
                    result=$(_install_one_tool "{}" "'"$manifest_file"'" "'"$downloads"'" "'"$REGISTRY_DIR"'")
                    echo "$result" >> "'"$result_file"'"
                '

            # 统计结果
            if [ -f "$result_file" ]; then
                installed=$(grep -c "^ok$" "$result_file" 2>/dev/null || echo 0)
                skipped=$(grep -c "^skip$" "$result_file" 2>/dev/null || echo 0)
                failed=$(grep -c "^fail$" "$result_file" 2>/dev/null || echo 0)
                rm -f "$result_file"
            fi
        fi

        ok "安装: ${installed} 成功  ${skipped} 跳过  ${failed} 失败"
    else
        if [ ! -d "$AI_HOME/tools/superpowers" ]; then
            _log "install" "未发现 download.manifest，跳过工具安装"
        fi
    fi

    # git 工具（superpowers）从 download/ 复制
    for git_tool in superpowers; do
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
                superpowers)
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
