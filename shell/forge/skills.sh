#!/usr/bin/env bash
# 命令: skills

SKILLS_DIR="$_ROOT/skills"

# 用 git sparse checkout 下载单个 skill 目录
_git_sparse_clone() {
    local repo="$1" src_path="$2" dest="$3"
    local tmp="$AI_HOME/tmp/.skill_$$"
    rm -rf "$tmp"
    mkdir -p "$tmp"

    git clone --depth 1 --filter=blob:none --sparse \
        "https://github.com/${repo}.git" "$tmp" 2>/dev/null || return 1
    git -C "$tmp" sparse-checkout set "$src_path" 2>/dev/null || return 1

    mkdir -p "$dest"
    if [ -d "$tmp/$src_path" ]; then
        cp -r "$tmp/$src_path"/* "$dest/" 2>/dev/null
        cp -r "$tmp/$src_path"/.[!.]* "$dest/" 2>/dev/null || true
    fi
    rm -rf "$tmp"
}

# 安装单个 skill
_install_one_skill() {
    local owner="$1" repo="$2" skill="$3"
    local dest="$SKILLS_DIR/$skill"
    [ -d "$dest/SKILL.md" ] && { echo -e "${Y}[已存在]${NC} $skill"; return 0; }
    [ -d "$dest" ] && [ -f "$dest/SKILL.md" ] && { echo -e "${Y}[已存在]${NC} $skill"; return 0; }

    echo -ne "${B}[下载]${NC} $owner/$repo/$skill ... "

    _git_sparse_clone "$owner/$repo" "skills/$skill" "$dest" && {
        echo -e "${G}ok${NC}"
        _skills_post_install "$skill" "$dest"
        return 0
    }

    _git_sparse_clone "$owner/$repo" "." "$dest" && {
        echo -e "${G}ok${NC}"
        _skills_post_install "$skill" "$dest"
        return 0
    }

    echo -e "${R}失败${NC}"
    return 1
}

# 安装后处理：依赖 + 链接
_skills_post_install() {
    local skill="$1" dest="$2"

    if [ -f "$dest/scripts/requirements.txt" ]; then
        echo -ne "  安装依赖 ... "
        pip3 install -q -r "$dest/scripts/requirements.txt" 2>/dev/null && echo -e "${G}ok${NC}" || echo -e "${Y}跳过${NC}"
    fi

    mkdir -p "$HOME/.claude/skills"
    ln -sfn "$dest" "$HOME/.claude/skills/$skill"
}

_skills_install() {
    local spec="$1"
    [ -z "$spec" ] && { echo "用法: forge skills install <owner/repo[/skill]>"; return 1; }

    local owner repo skill
    IFS='/' read -r owner repo skill <<< "$spec"

    if [ -z "$skill" ]; then
        echo -e "${B}[插件]${NC} $owner/$repo"
        local tmp="$AI_HOME/tmp/.plugin_$$"
        rm -rf "$tmp"
        git clone --depth 1 "https://github.com/${owner}/${repo}.git" "$tmp" 2>/dev/null || {
            echo -e "${R}[错误]${NC} 无法克隆 $owner/$repo"
            return 1
        }

        local -a skills_list=()

        if [ -f "$tmp/.claude-plugin/marketplace.json" ]; then
            while IFS= read -r s; do
                [ -n "$s" ] && skills_list+=("$(basename "$s")")
            done < <(python3 -c "
import json,sys
d=json.load(open('$tmp/.claude-plugin/marketplace.json'))
for p in d.get('plugins',[]):
    for s in p.get('skills',[]):
        print(s)
" 2>/dev/null || true)
        fi

        if [ "${#skills_list[@]}" -eq 0 ] && [ -d "$tmp/skills" ]; then
            for d in "$tmp/skills"/*/; do
                [ -f "${d}SKILL.md" ] && skills_list+=("$(basename "$d")")
            done
        fi

        if [ "${#skills_list[@]}" -eq 0 ] && [ -f "$tmp/SKILL.md" ]; then
            skills_list+=("$repo")
            mkdir -p "$SKILLS_DIR/$repo"
            cp -r "$tmp"/* "$SKILLS_DIR/$repo/" 2>/dev/null
            cp -r "$tmp"/.[!.]* "$SKILLS_DIR/$repo/" 2>/dev/null || true
            _skills_post_install "$repo" "$SKILLS_DIR/$repo"
            echo -e "${G}[完成]${NC} $repo"
            rm -rf "$tmp"
            return 0
        fi

        if [ "${#skills_list[@]}" -eq 0 ]; then
            echo -e "${Y}[注意]${NC} 未找到任何 skill"
            rm -rf "$tmp"
            return 1
        fi
        local ok=0 fail=0
        for s in "${skills_list[@]}"; do
            local dest="$SKILLS_DIR/$s"
            if [ -d "$tmp/skills/$s" ]; then
                mkdir -p "$dest"
                cp -r "$tmp/skills/$s"/* "$dest/" 2>/dev/null
                cp -r "$tmp/skills/$s"/.[!.]* "$dest/" 2>/dev/null || true
                _skills_post_install "$s" "$dest"
                echo -e "  ${G}✓${NC} $s"
                ((ok++)) || true
            else
                echo -e "  ${R}✗${NC} $s (未找到)"
                ((fail++)) || true
            fi
        done
        rm -rf "$tmp"
        echo -e "\n${BOLD}完成:${NC} ${G}${ok} 成功${NC}  ${R}${fail} 失败${NC}"
        return 0
    fi

    _install_one_skill "$owner" "$repo" "$skill"
}

_skills_list() {
    echo -e "\n${BOLD}已安装 Skills${NC}"
    echo -e "${D}$(printf '%.0s─' {1..40})${NC}"
    local count=0
    for d in "$SKILLS_DIR"/*/; do
        [ -d "$d" ] || continue
        local name
        name=$(basename "$d")
        local desc=""
        [ -f "$d/SKILL.md" ] && desc=$(sed -n 's/^description: //p' "$d/SKILL.md" | head -1 | sed 's/^"//;s/"$//')
        printf "  %-24s %s\n" "$name" "${desc:0:50}"
        ((count++)) || true
    done
    [ $count -eq 0 ] && echo -e "  ${D}(无)${NC}"
    echo ""
}

_skills_remove() {
    local name="$1"
    [ -z "$name" ] && { echo "用法: forge skills remove <name>"; return 1; }
    local dest="$SKILLS_DIR/$name"
    [ ! -d "$dest" ] && { echo -e "${Y}[跳过]${NC} $name 未安装"; return 0; }
    rm -rf "$dest"
    rm -f "$HOME/.claude/skills/$name"
    echo -e "${G}[删除]${NC} $name"
}

cmd_skills() {
    local subcmd="${1:-}"
    shift 2>/dev/null || true
    case "$subcmd" in
        install)  _skills_install "$@" ;;
        list|ls)  _skills_list ;;
        remove|rm) _skills_remove "$@" ;;
        *)
            echo "用法: forge skills <子命令>"
            echo ""
            echo "  install <owner/repo/skill>  下载 skill"
            echo "  list                        显示已安装 skills"
            echo "  remove <name>               删除 skill"
            ;;
    esac
}
