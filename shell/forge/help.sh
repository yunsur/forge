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
  forge init                               解压并部署到运行环境
  forge uninstall                          卸载指定工具

  forge new <name>                         生成新工具的 manifest 模板
  forge pack [file.tgz]                    打包整站用于内网迁移

  forge skills install <owner/repo/skill>  下载 skill
  forge skills list                        显示已安装 skills
  forge skills remove <name>               删除 skill

  forge doctor                             环境检查

EOF
}
