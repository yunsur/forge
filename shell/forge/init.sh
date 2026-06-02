#!/usr/bin/env bash
# 命令: init — 运行环境初始化
#
# 统一原则：所有文件先复制到 ai/，再从 ai/ 软链接到目标位置
#
# 子命令:
#   forge init            全量初始化（解压+配置+skills+mcp+链接）
#   forge init tools      仅解压工具
#   forge init config     仅部署配置文件
#   forge init skills     仅部署 Skills
#   forge init mcp        仅合并 MCP 配置
#   forge init bins       仅链接二进制

# ── tools ───────────────────────────────────────────────────

_init_tools() {
    local manifest_file="$ROOT_DIR/download/download.manifest"
    local downloads="$ROOT_DIR/download"

    mkdir -p "$AI_HOME/tools" "$AI_HOME/runtimes"

    # 从 download.manifest 解压
    if [ -f "$manifest_file" ]; then
        _log "init" "解压工具（从 download.manifest）"

        declare -A TOOL_FILES
        declare -a TOOL_ORDER
        while IFS='|' read -r tname tver tfile; do
            [ -z "$tname" ] && continue
            if [ -z "$tfile" ]; then
                tfile="$tver"
                tver=""
            fi
            if [ -z "${TOOL_FILES[$tname]:-}" ]; then
                TOOL_ORDER+=("$tname")
                TOOL_FILES[$tname]="$tfile"
            else
                TOOL_FILES[$tname]="${TOOL_FILES[$tname]} $tfile"
            fi
        done < "$manifest_file"

        local extracted=0 skipped=0 failed=0

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
                            ((extracted++)) || true
                        else
                            err "$tool 解压失败: $fname"
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

        ok "解压: ${extracted} 成功  ${skipped} 跳过  ${failed} 失败"
    else
        if [ ! -d "$AI_HOME/tools/gstack" ] && [ ! -d "$AI_HOME/tools/superpowers" ]; then
            _log "init" "未发现 download.manifest，跳过工具解压"
        fi
    fi

    # git 工具（gstack、superpowers）
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
}

# ── dirs ────────────────────────────────────────────────────

_init_dirs() {
    _log "init" "创建基础目录"
    mkdir -p "$AI_HOME/bin" "$AI_HOME/tools" "$AI_HOME/runtimes" "$AI_HOME/tmp"
    mkdir -p "$HOME/.claude/skills"
    # env.sh 拷贝到 AI_HOME，使 ai/ 完全脱离 forge/
    if [ -f "$ROOT_DIR/shell/env.sh" ]; then
        cp "$ROOT_DIR/shell/env.sh" "$AI_HOME/env.sh"
    fi
    ok "目录就绪"
}

# ── config ──────────────────────────────────────────────────

_init_config() {
    _log "init" "部署配置文件"

    if [ -d "$ROOT_DIR/config/openspec" ]; then
        mkdir -p "$AI_HOME/config/openspec" "$HOME/.config/openspec"
        cp -r "$ROOT_DIR/config/openspec/"* "$AI_HOME/config/openspec/" 2>/dev/null || true
        for f in "$AI_HOME/config/openspec"/*; do
            [ -f "$f" ] && ln -sfn "$f" "$HOME/.config/openspec/$(basename "$f")"
        done
        ok "openspec 配置 → ~/.config/openspec/"
    fi

    if [ -d "$ROOT_DIR/config/claude" ]; then
        mkdir -p "$AI_HOME/config/claude" "$HOME/.claude/agents"
        cp -r "$ROOT_DIR/config/claude/"* "$AI_HOME/config/claude/" 2>/dev/null || true
        [ -f "$AI_HOME/config/claude/CLAUDE.md" ] && \
            ln -sfn "$AI_HOME/config/claude/CLAUDE.md" "$HOME/.claude/CLAUDE.md"
        for f in "$AI_HOME/config/claude/agents"/*.md; do
            [ -f "$f" ] && ln -sfn "$f" "$HOME/.claude/agents/$(basename "$f")"
        done
        ok "claude 配置 → ~/.claude/ (软链接)"
    fi
}

# ── skills ──────────────────────────────────────────────────

_init_skills() {
    local downloads="$ROOT_DIR/download"
    local builtin_skills="$ROOT_DIR/config/claude/skills"

    _log "init" "部署 Skills"

    # 先清理目标目录，避免残留旧 skills
    if [ -d "$HOME/.claude/skills" ]; then
        rm -rf "$HOME/.claude/skills"
        _log "init" "已清理 ~/.claude/skills"
    fi

    mkdir -p "$AI_HOME/skills" "$HOME/.claude/skills"

    # 仓库内置 skills（config/claude/skills）
    local builtin_count=0
    if [ -d "$builtin_skills" ]; then
        for d in "$builtin_skills"/*/; do
            [ -d "$d" ] || continue
            local sname
            sname=$(basename "$d")
            rm -rf "$AI_HOME/skills/$sname"
            cp -r "$d" "$AI_HOME/skills/$sname"
            ln -sfn "$AI_HOME/skills/$sname" "$HOME/.claude/skills/$sname"
            ((builtin_count++)) || true
        done
        [ $builtin_count -gt 0 ] && ok "内置 skills: ${builtin_count} 个"
    fi

    # 独立 skills（download/skills/，非 superpowers/gstack）
    local skill_count=0
    if [ -d "$downloads/skills" ]; then
        for d in "$downloads/skills"/*/; do
            [ -d "$d" ] || continue
            local sname
            sname=$(basename "$d")
            rm -rf "$AI_HOME/skills/$sname"
            cp -r "$d" "$AI_HOME/skills/$sname"
            ln -sfn "$AI_HOME/skills/$sname" "$HOME/.claude/skills/$sname"
            ((skill_count++)) || true
        done
        [ $skill_count -gt 0 ] && ok "独立 skills: ${skill_count} 个"
    fi

    local SUPERPOWERS_SKILLS=(
        # 测试驱动开发
        test-driven-development
        # 系统化调试
        systematic-debugging
        # 完成前验证
        verification-before-completion
        # 工程代码审查
        requesting-code-review
    )
    if [ -d "$AI_HOME/tools/superpowers/skills" ]; then
        local sp_count=0
        for skill in "${SUPERPOWERS_SKILLS[@]}"; do
            if [ -d "$AI_HOME/tools/superpowers/skills/$skill" ]; then
                ln -sfn "$AI_HOME/tools/superpowers/skills/$skill" "$HOME/.claude/skills/sp-${skill}"
                ((sp_count++)) || true
            fi
        done
        ok "superpowers skills: ${sp_count}/${#SUPERPOWERS_SKILLS[@]} 个"
    fi

    local GSTACK_SKILLS=(
        # 需求/方案挑战
        office-hours
        # 设计评审
        review
        # 问题调查
        investigate
        # QA/验收
        qa-only
    )
    if [ -d "$AI_HOME/tools/gstack" ]; then
        local gs_count=0
        for skill in "${GSTACK_SKILLS[@]}"; do
            if [ -d "$AI_HOME/tools/gstack/$skill" ]; then
                ln -sfn "$AI_HOME/tools/gstack/$skill" "$HOME/.claude/skills/gstack-${skill}"
                ((gs_count++)) || true
            fi
        done
        ok "gstack skills: ${gs_count}/${#GSTACK_SKILLS[@]} 个"

        # 裁剪 llms.txt，只保留白名单内的 skills 条目
        local llms_file="$AI_HOME/tools/gstack/gstack/llms.txt"
        if [ -f "$llms_file" ]; then
            local tmp="$llms_file.tmp"
            local in_skills=0
            while IFS= read -r line; do
                if [[ "$line" == "## Skills" ]]; then
                    in_skills=1
                    echo "$line" >> "$tmp"
                    continue
                fi
                if [ "$in_skills" -eq 0 ]; then
                    echo "$line" >> "$tmp"
                    continue
                fi
                # Skills 段：只保留白名单条目
                if [[ "$line" == "- [/"* ]]; then
                    local name="${line#- [/}"
                    name="${name%%]*}"
                    local keep=0
                    for skill in "${GSTACK_SKILLS[@]}"; do
                        [ "$name" = "$skill" ] && { keep=1; break; }
                    done
                    [ "$keep" -eq 1 ] && echo "$line" >> "$tmp"
                else
                    echo "$line" >> "$tmp"
                fi
            done < "$llms_file"
            mv "$tmp" "$llms_file"
            ok "llms.txt 已裁剪为白名单 (${#GSTACK_SKILLS[@]} 个 skills)"
        fi
    fi
}

# ── mcp ─────────────────────────────────────────────────────

_init_mcp() {
    _log "init" "部署 MCP 配置"

    mkdir -p "$AI_HOME/mcp"

    if [ -f "$ROOT_DIR/config/claude/mcp.json" ]; then
        cp "$ROOT_DIR/config/claude/mcp.json" "$AI_HOME/mcp/claude.json" 2>/dev/null || true
    fi

    if [ "$(ls -A "$AI_HOME/mcp/"*.json 2>/dev/null)" ]; then
        if command -v python3 &>/dev/null; then
            python3 -c "
import json,os,glob
base={'mcpServers':{}}
for f in sorted(glob.glob('$AI_HOME/mcp/*.json')):
    with open(f) as fh: d=json.load(fh)
    base['mcpServers'].update(d.get('mcpServers',{}))
with open('$HOME/.claude/mcp.json','w') as fh: json.dump(base,fh,indent=2)
print(f'  mcp servers: {len(base[\"mcpServers\"])} 个')
" 2>/dev/null && ok "MCP → ~/.claude/mcp.json" || warn "MCP 合并失败（需要 python3）"
        else
            warn "python3 不可用，跳过 MCP 合并"
        fi
    fi
}

# ── bins ────────────────────────────────────────────────────

_init_bins() {
    mkdir -p "$AI_HOME/bin"

    _log "init" "链接工具二进制"

    _tool_bins() {
        case "$1" in
            rg) echo "rg" ;;
            fd) echo "fd" ;;
            fzf) echo "fzf" ;;
            jq) echo "jq" ;;
            yq) echo "yq" ;;
            bat) echo "bat" ;;
            eza) echo "eza" ;;
            delta) echo "delta" ;;
            lazygit) echo "lazygit" ;;
            just) echo "just" ;;
            uv) echo "uv uvx" ;;
            claude) echo "claude" ;;
            codex) echo "codex" ;;
            bun) echo "bun" ;;
            ast-grep) echo "sg" ;;
            node) echo "bin/node bin/npm bin/npx" ;;
            go) echo "bin/go bin/gofmt" ;;
            rust) echo "bin/rustc bin/cargo bin/rustup bin/rustfmt bin/cargo-clippy" ;;
            openspec) echo "bin/openspec" ;;
            pyenv) echo "bin/pyenv" ;;
            starship) echo "starship" ;;
            cc-switch-cli) echo "cc-switch" ;;
        esac
    }

    local linked=0

    for tool_dir in "$AI_HOME/tools"/*/; do
        [ -d "$tool_dir" ] || continue
        local tool_name=$(basename "$tool_dir")
        local bins=$(_tool_bins "$tool_name")
        [ -z "$bins" ] && continue

        for bin_rel in $bins; do
            local src="$tool_dir/$bin_rel"
            local bname=$(basename "$bin_rel")
            if [ -f "$src" ] && [ ! -L "$AI_HOME/bin/$bname" ]; then
                ln -sf "$src" "$AI_HOME/bin/$bname"
                ((linked++)) || true
            fi
        done
    done

    for rt_dir in "$AI_HOME/runtimes"/*/; do
        [ -d "$rt_dir" ] || continue
        local rt_name=$(basename "$rt_dir")
        local bins=$(_tool_bins "$rt_name")
        [ -z "$bins" ] && continue

        for bin_rel in $bins; do
            local src="$rt_dir/$bin_rel"
            local bname=$(basename "$bin_rel")
            if [ -f "$src" ] && [ ! -L "$AI_HOME/bin/$bname" ]; then
                ln -sf "$src" "$AI_HOME/bin/$bname"
                ((linked++)) || true
            fi
        done
    done

    ok "新链接: ${linked} 个二进制 → ai/bin/"

    # 自定义脚本
    if [ -d "$ROOT_DIR/bin" ]; then
        local custom=0
        for f in "$ROOT_DIR/bin"/*; do
            [ -f "$f" ] || continue
            local bname=$(basename "$f")
            if [ ! -L "$AI_HOME/bin/$bname" ]; then
                ln -sf "$f" "$AI_HOME/bin/$bname"
                ((custom++)) || true
            fi
        done
        [ $custom -gt 0 ] && ok "自定义脚本: ${custom} 个"
    fi
}

# ── 主入口 ──────────────────────────────────────────────────

cmd_init() {
    # 开发环境安全防护：禁止在 forge 仓库内生成 ai/
    if is_forge_dev; then
        err "当前为开发环境（forge 仓库内），禁止执行 init"
        echo -e "  ${D}如需强制执行: FORGE_SKIP_DEV_CHECK=1 forge init${NC}"
        return 1
    fi

    case "${1:-}" in
        tools)          _init_tools ;;
        config)         _init_config ;;
        skills)         _init_skills ;;
        mcp)            _init_mcp ;;
        bins)           _init_bins ;;
        "")
            _init_tools
            _init_dirs
            _init_config
            _init_skills
            _init_mcp
            _init_bins

            echo ""
            echo -e "${G}${BOLD}初始化完成！${NC}"
            echo ""
            echo -e "  加载环境:  ${B}source ${AI_HOME}/env.sh${NC}"
            echo -e "  检查环境:  ${B}forge doctor${NC}"
            echo ""
            echo -e "  ${D}提示: 将以下内容添加到 ~/.bashrc 或 ~/.zshrc:${NC}"
            echo -e "  ${D}source ${AI_HOME}/env.sh${NC}"
            echo ""
            ;;
        *)
            err "未知子命令: forge init $1"
            echo "用法: forge init [tools|config|skills|mcp|bins]"
            return 1
            ;;
    esac
}
