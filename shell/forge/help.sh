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
  forge download [--force]                 只下载不解压（--force 强制重新下载）
  forge install [tool...]                  安装环境无关工具（解压+链接，无需运行时）
  forge init                               初始化环境依赖工具+配置（pyenv-virtualenv、python、speckit）
  forge init tools                         仅安装环境依赖工具
  forge init config                        仅部署配置文件
  forge init skills                        仅部署 Skills
  forge init mcp                           仅合并 MCP 配置
  forge init bins                          仅链接二进制
  forge uninstall                          卸载指定工具

  forge new <name>                         生成新工具的 manifest 模板
  forge pack [config|full]                 打包用于迁移（config=仅配置，full=全量默认）
  forge merge config <archive.tgz>         合并配置包到当前环境
  forge push <user@host[:port]> [path]     打包并 scp 到远程（默认 /tmp）

  forge skills install <owner/repo/skill>  下载 skill
  forge skills list                        显示已安装 skills
  forge skills remove <name>               删除 skill

  forge mcp install                        安装 MCP server 包
  forge mcp list                           显示 MCP server 配置

  forge doctor                             环境检查

EOF
}
