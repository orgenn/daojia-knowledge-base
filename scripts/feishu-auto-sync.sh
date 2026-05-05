#!/bin/bash
# 飞书云盘自动同步脚本
# 支持定时任务自动同步

echo "=========================================="
echo "   飞书云盘自动同步"
echo "=========================================="
echo ""

# 颜色定义
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

# 路径配置
KNOWLEDGE_BASE="$HOME/文档/道家知识库01"
HAOZE_BASE="$HOME/文档/haoze"
XUANMEN_BASE="$HOME/文档/xuanmen"
LARK_CLI="lark-cli"

# 配置文件
CONFIG_FILE="$HOME/.feishu-sync.conf"
LOG_FILE="$KNOWLEDGE_BASE/scripts/feishu-auto-sync.log"

# 日志函数
log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1" >> "$LOG_FILE"
    echo -e "$1"
}

# 加载配置
load_config() {
    if [ -f "$CONFIG_FILE" ]; then
        source "$CONFIG_FILE"
    else
        log "${RED}错误: 配置文件不存在${NC}"
        echo "请先运行 feishu-sync.sh 进行配置"
        exit 1
    fi
    
    if [ -z "$FEISHU_FOLDER_TOKEN" ]; then
        log "${RED}错误: 未配置飞书文件夹Token${NC}"
        exit 1
    fi
}

# 同步单个目录
sync_directory() {
    local local_dir="$1"
    local dir_name="$2"
    local direction="${3:-push}"  # push 或 pull
    
    if [ ! -d "$local_dir" ]; then
        log "${YELLOW}警告: 目录不存在 - $local_dir${NC}"
        return 1
    fi
    
    log "${GREEN}同步 $dir_name ($direction)${NC}"
    
    case $direction in
        "push")
            $LARK_CLI drive +push \
                --folder-token "$FEISHU_FOLDER_TOKEN" \
                --local-dir "$local_dir" \
                --if-exists skip \
                2>&1 | tail -5 | tee -a "$LOG_FILE"
            ;;
        "pull")
            $LARK_CLI drive +pull \
                --folder-token "$FEISHU_FOLDER_TOKEN" \
                --local-dir "$local_dir" \
                --if-exists skip \
                2>&1 | tail -5 | tee -a "$LOG_FILE"
            ;;
        "sync")
            # 先pull再push
            $LARK_CLI drive +pull \
                --folder-token "$FEISHU_FOLDER_TOKEN" \
                --local-dir "$local_dir" \
                --if-exists skip \
                2>&1 | tail -3 | tee -a "$LOG_FILE"
            $LARK_CLI drive +push \
                --folder-token "$FEISHU_FOLDER_TOKEN" \
                --local-dir "$local_dir" \
                --if-exists skip \
                2>&1 | tail -3 | tee -a "$LOG_FILE"
            ;;
    esac
    
    log "${GREEN}✓ $dir_name 同步完成${NC}"
}

# 主函数
main() {
    load_config
    
    log "${GREEN}开始飞书自动同步${NC}"
    log "时间: $(date '+%Y-%m-%d %H:%M:%S')"
    log "方向: ${1:-push}"
    
    # 同步方向
    direction="${1:-push}"
    
    # 同步各个知识库
    sync_directory "$KNOWLEDGE_BASE" "道家知识库" "$direction"
    sync_directory "$HAOZE_BASE" "灏泽知识库" "$direction"
    sync_directory "$XUANMEN_BASE" "玄门知识库" "$direction"
    
    log "${GREEN}自动同步完成${NC}"
}

# 执行主函数
main "$@"
