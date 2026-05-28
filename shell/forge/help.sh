#!/usr/bin/env bash
# 帮助信息

show_help() {
    cat << 'EOF'

forge - AI 工具版本管理器

用法:
  forge                                    检查并提示更新
  forge -a                                 检查并更新全部

  forge list                               显示所有工具状态
  forge update                             仅检查可用更新
  forge download                           只下载不解压
  forge init                               全量初始化（解压+配置+skills+mcp+链接）
  forge init tools                         仅解压工具
  forge init config                        仅部署配置文件
  forge init skills                        仅部署 Skills
  forge init mcp                           仅合并 MCP 配置
  forge init bins                          仅链接二进制
  forge uninstall                          卸载指定工具

  forge new <name>                         生成新工具的 manifest 模板
  forge pack [file.tgz]                    打包整站用于内网迁移

  forge skills install <owner/repo/skill>  下载 skill
  forge skills list                        显示已安装 skills
  forge skills remove <name>               删除 skill

  forge mcp install                        安装 MCP server 包
  forge mcp list                           显示 MCP server 配置

  forge doctor                             环境检查

EOF
}
