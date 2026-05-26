#!/usr/bin/env bash
# 命令: list

cmd_list() {
    load_registry
    print_header "工具" "当前版本" "最新版本"

    for manifest in "${REGISTRY[@]}"; do
        local name current latest
        name=$(meta_get "$manifest" "name")
        current=$(get_installed "$name")
        [ -z "$current" ] && current=$(get_downloaded "$name")
        latest=$(get_latest_cached "$name")

        if [ -z "$current" ] && [ -z "$latest" ]; then
            _pad "$name" 16
            _pad "-" 12
            _pad "-" 12
            echo ""
        elif [ -n "$current" ] && [ -n "$latest" ] && [ "$current" != "$latest" ]; then
            _pad "$name" 16
            _pad "$current" 12
            _pad "${Y}${latest}${NC}" 12
            echo ""
        else
            _pad "$name" 16
            _pad "${current:--}" 12
            _pad "${latest:--}" 12
            echo ""
        fi
    done
    echo ""
}
