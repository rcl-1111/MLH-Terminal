#!/bin/bash
# MLH-Terminal.sh

# 设置颜色代码
RED='\033[1;31m'
GREEN='\033[1;32m'
YELLOW='\033[1;33m'
BLUE='\033[1;34m'
MAGENTA='\033[1;35m'
CYAN='\033[1;36m'
WHITE='\033[1;37m'
BOLD='\033[1m'
NC='\033[0m' # 重置颜色

# 获取MLH-Terminal的根目录
MLH_ROOT_PATH="$(cd "$(dirname "$0")/../.." && pwd)"
COMMANDS_DIR="${MLH_ROOT_PATH}/File/Commands"
CONFIG_FILE="${MLH_ROOT_PATH}/Data/config"
HISTORY_FILE="${MLH_ROOT_PATH}/Data/history"
LOG_FILE="${MLH_ROOT_PATH}/Data/terminal.log"

# 创建必要的目录
create_directories() {
    mkdir -p "$(dirname "$COMMANDS_DIR")"
    mkdir -p "$(dirname "$CONFIG_FILE")"
    mkdir -p "$(dirname "$LOG_FILE")"
}

# 记录日志
log_message() {
    local level="$1"
    local message="$2"
    local timestamp=$(date '+%Y-%m-%d %H:%M:%S')
    echo "[$timestamp] [$level] $message" >> "$LOG_FILE"
}

# 配置文件处理函数
load_config() {
    if [ -f "$CONFIG_FILE" ]; then
        source "$CONFIG_FILE"
        log_message "INFO" "配置文件已加载: $CONFIG_FILE"
    else
        # 创建默认配置文件
        cat > "$CONFIG_FILE" << EOF
# MLH-Terminal 配置文件
TERMINAL_NAME="MLH Terminal"
SHOW_WELCOME=true
SHOW_PATH=true
ENABLE_HISTORY=true
LOG_LEVEL="INFO"
PROMPT_COLOR="${GREEN}"
PATH_COLOR="${CYAN}"
EOF
        log_message "INFO" "已创建默认配置文件: $CONFIG_FILE"
    fi
}

# 加载配置文件
load_config

# 显示欢迎信息
show_welcome() {
    if [ "$SHOW_WELCOME" != "false" ]; then
        echo -e "${BLUE}╔══════════════════════════════════════════════╗${NC}"
        echo -e "${BLUE}║${NC}    ${GREEN}欢迎使用 MLH-Terminal${NC}    ${BLUE}║${NC}"
        echo -e "${BLUE}║${NC}  输入 'help' 获取帮助信息   ${BLUE}║${NC}"
        echo -e "${BLUE}╚══════════════════════════════════════════════╝${NC}"
        echo ""
    fi
}

# 获取美化后的路径
get_beautified_path() {
    local current_dir=$(pwd)
    local home_dir="$HOME"
    
    # 如果是家目录，显示~
    if [ "$current_dir" = "$home_dir" ]; then
        echo "~"
    elif [ "${current_dir#$home_dir/}" != "$current_dir" ]; then
        # 如果在home的子目录中，用~代替home路径
        echo "~/${current_dir#$home_dir/}"
    else
        # 显示完整路径
        echo "$current_dir"
    fi
}

# 安全执行系统命令
safe_execute_system_command() {
    local input="$1"
    
    # 检查命令是否存在
    local cmd
    cmd=$(echo "$input" | awk '{print $1}')
    
    if ! command -v "$cmd" > /dev/null 2>&1; then
        echo -e "${RED}错误: 命令 '$cmd' 未找到${NC}"
        echo -e "建议:"
        echo -e "  1. 检查命令拼写"
        echo -e "  2. 使用 'which' 命令查找"
        echo -e "  3. 如果需要安装，使用 'pkg install' 或 'apt install'"
        return 127
    fi
    
    # 执行命令
    eval "$input"
    return $?
}

# 检查是否是自定义命令
is_custom_command() {
    local cmd="$1"
    if [ -x "${COMMANDS_DIR}/${cmd}" ]; then
        return 0
    else
        return 1
    fi
}

# 执行自定义命令
exec_custom_command() {
    local cmd="$1"
    shift
    local args=("$@")
    
    if [ -x "${COMMANDS_DIR}/${cmd}" ]; then
        # 记录命令执行
        log_message "COMMAND" "执行自定义命令: $cmd ${args[*]}"
        # 执行命令
        "${COMMANDS_DIR}/${cmd}" "${args[@]}"
        local exit_code=$?
        log_message "COMMAND" "自定义命令 '$cmd' 退出码: $exit_code"
        return $exit_code
    else
        echo -e "${RED}错误: 找不到自定义命令 '${cmd}'${NC}"
        log_message "ERROR" "未找到自定义命令: $cmd"
        return 1
    fi
}

# 内置帮助命令
show_builtin_help() {
    echo -e "${CYAN}${BOLD}MLH Terminal 内置命令:${NC}"
    echo -e "  help           - 显示此帮助信息"
    echo -e "  version        - 显示版本信息"
    echo -e "  config         - 显示配置文件路径"
    echo -e "  reload         - 重新加载配置文件"
    echo -e "  clear          - 清屏"
    echo -e "  exit/quit      - 退出终端"
    echo -e ""
    echo -e "${CYAN}${BOLD}自定义命令目录:${NC} $COMMANDS_DIR"
    echo -e ""
    echo -e "${YELLOW}${BOLD}使用提示:${NC}"
    echo -e "  • 可以直接执行原版Termux命令"
    echo -e "  • 使用 Ctrl+C 取消当前命令"
    echo -e "  • 使用 Ctrl+D 快速退出"
    echo -e "  • 自定义命令优先级高于系统命令"
    echo -e ""
    echo -e "${MAGENTA}${BOLD}创建自定义命令:${NC}"
    echo -e "  1. 在 $COMMANDS_DIR/ 中创建脚本"
    echo -e "  2. 添加执行权限: chmod +x 命令名"
    echo -e "  3. 无需重启即可使用"
}

# 内置版本命令
show_version() {
    echo -e "${CYAN}${BOLD}MLH Terminal 信息${NC}"
    echo -e "  版本: v1.1"
    echo -e "  作者: rcl-1111"
    echo -e "  创建时间: 2026年4月"
    echo -e "  根目录: $MLH_ROOT_PATH"
    echo -e "  配置文件: $CONFIG_FILE"
    echo -e "  日志文件: $LOG_FILE"
    echo -e ""
    echo -e "${GREEN}系统信息:${NC}"
    echo -e "  系统: $(uname -s) $(uname -m)"
    echo -e "  Shell: $SHELL"
    echo -e "  当前用户: $(whoami)"
    echo -e "  主机名: $(hostname)"
}

# 内置清屏命令
clear_screen() {
    clear
    # 重新显示欢迎信息
    if [ "$SHOW_WELCOME" != "false" ]; then
        show_welcome
    fi
}

# 显示系统信息
show_system_info() {
    echo -e "${CYAN}${BOLD}系统状态${NC}"
    echo -e "  当前目录: $(pwd)"
    echo -e "  磁盘空间: $(df -h . | tail -1 | awk '{print $4}') 可用"
    echo -e "  内存使用: $(free -m | awk 'NR==2{printf "%.1f%% of %sMB", $3*100/$2, $2}')"
    echo -e "  进程数: $(ps aux | wc -l)"
}

# 命令历史管理
init_history() {
    if [ "$ENABLE_HISTORY" != "false" ]; then
        # 设置历史记录
        HISTFILE="$HISTORY_FILE"
        HISTSIZE=1000
        HISTFILESIZE=2000
        # 启用历史记录
        set -o history
        # 加载历史记录
        if [ -f "$HISTFILE" ]; then
            history -r "$HISTFILE"
        fi
    fi
}

# 保存历史记录
save_history() {
    if [ "$ENABLE_HISTORY" != "false" ] && [ -n "$input" ]; then
        history -a "$HISTORY_FILE"
    fi
}

# 处理命令输入
process_input() {
    local input="$1"
    local cmd
    local args
    
    # 分割命令和参数
    read -r cmd args <<< "$input"
    
    # 处理空输入
    if [ -z "$cmd" ]; then
        return 0
    fi
    
    # 记录命令
    log_message "INPUT" "用户输入: $input"
    
    # 处理退出命令
    if [[ "$cmd" == "exit" || "$cmd" == "quit" ]]; then
        echo -e "${GREEN}感谢使用 ${TERMINAL_NAME}，再见！${NC}"
        save_history
        exit 0
    fi
    
    # 处理内置命令
    case "$cmd" in
        "help")
            show_builtin_help
            return 0
            ;;
        "version")
            show_version
            return 0
            ;;
        "config")
            echo -e "${CYAN}${BOLD}配置文件路径:${NC} $CONFIG_FILE"
            echo -e "${CYAN}${BOLD}自定义命令目录:${NC} $COMMANDS_DIR"
            echo -e "${CYAN}${BOLD}历史记录文件:${NC} $HISTORY_FILE"
            echo -e "${CYAN}${BOLD}日志文件:${NC} $LOG_FILE"
            return 0
            ;;
        "reload")
            load_config
            echo -e "${GREEN}配置文件已重新加载${NC}"
            return 0
            ;;
        "clear")
            clear_screen
            return 0
            ;;
        "info")
            show_system_info
            return 0
            ;;
    esac
    
    # 处理自定义命令
    if is_custom_command "$cmd"; then
        exec_custom_command "$cmd" $args
        return $?
    fi
    
    # 执行系统命令
    safe_execute_system_command "$input"
    local exit_code=$?
    
    if [ $exit_code -ne 0 ]; then
        log_message "ERROR" "命令执行失败: $input (退出码: $exit_code)"
    fi
    
    return $exit_code
}

# 显示提示符
show_prompt() {
    local prompt_path
    local prompt_symbol=">"
    
    if [ "$SHOW_PATH" != "false" ]; then
        prompt_path=$(get_beautified_path)
        echo -ne "${PATH_COLOR}${prompt_path}${NC}${PROMPT_COLOR}${prompt_symbol}${NC} "
    else
        echo -ne "${PROMPT_COLOR}${prompt_symbol}${NC} "
    fi
}

# 主程序
main() {
    # 创建必要的目录
    create_directories
    
    # 初始化历史记录
    init_history
    
    # 显示欢迎信息
    clear_screen
    
    # 主循环
    while true; do
        # 显示提示符
        show_prompt
        
        # 读取输入
        if ! read -e input; then
            # 处理 Ctrl+D
            echo  # 换行
            echo -e "${GREEN}感谢使用 ${TERMINAL_NAME}，再见！${NC}"
            save_history
            exit 0
        fi
        
        # 添加到历史记录
        if [ "$ENABLE_HISTORY" != "false" ]; then
            history -s "$input"
        fi
        
        # 处理输入
        process_input "$input"
        
        # 保存历史记录
        save_history
    done
}

# 设置信号处理
trap 'echo -e "\n${YELLOW}操作被中断${NC}"; save_history; exit 1' INT
trap 'save_history; exit 0' EXIT

# 程序入口
main "$@"
