#!/bin/bash
# 知识库全量同步脚本
# 同步道家知识库、灏泽知识库、玄门知识库到GBrain和OpenCode

echo "=========================================="
echo "   知识库全量同步脚本"
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
GBRAIN_CMD="$HOME/.bun/bin/gbrain"
OPENCODE_DIR="$HOME/.opencode"

# 日志文件
LOG_FILE="$KNOWLEDGE_BASE/scripts/sync.log"

# 日志函数
log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1" >> "$LOG_FILE"
    echo -e "$1"
}

# 检查依赖
check_dependencies() {
    log "${GREEN}=== 检查依赖 ===${NC}"
    
    if [ ! -f "$GBRAIN_CMD" ]; then
        log "${RED}错误: GBrain未安装${NC}"
        exit 1
    fi
    
    if [ ! -d "$KNOWLEDGE_BASE" ]; then
        log "${RED}错误: 道家知识库不存在${NC}"
        exit 1
    fi
    
    log "${GREEN}✓ 依赖检查通过${NC}"
}

# 同步道家知识库到GBrain
sync_daojia_to_gbrain() {
    log "${GREEN}=== 同步道家知识库到GBrain ===${NC}"
    
    # 导入新内容
    $GBRAIN_CMD import "$KNOWLEDGE_BASE/" --no-embed 2>&1 | tail -5
    
    log "${GREEN}✓ 道家知识库同步完成${NC}"
}

# 同步灏泽知识库到GBrain
sync_haoze_to_gbrain() {
    log "${GREEN}=== 同步灏泽知识库到GBrain ===${NC}"
    
    if [ -d "$HAOZE_BASE/正文" ]; then
        # 按分类导入，避免超时
        for category in "$HAOZE_BASE/正文"/*/; do
            if [ -d "$category" ]; then
                category_name=$(basename "$category")
                log "  导入: $category_name"
                $GBRAIN_CMD import "$category" --no-embed 2>&1 | tail -2
            fi
        done
    fi
    
    log "${GREEN}✓ 灏泽知识库同步完成${NC}"
}

# 同步玄门知识库到GBrain
sync_xuanmen_to_gbrain() {
    log "${GREEN}=== 同步玄门知识库到GBrain ===${NC}"
    
    if [ -d "$XUANMEN_BASE/wiki" ]; then
        $GBRAIN_CMD import "$XUANMEN_BASE/wiki/" --no-embed 2>&1 | tail -5
    fi
    
    log "${GREEN}✓ 玄门知识库同步完成${NC}"
}

# 生成嵌入向量
generate_embeddings() {
    log "${GREEN}=== 生成嵌入向量 ===${NC}"
    
    $GBRAIN_CMD embed --stale 2>&1 | tail -5
    
    log "${GREEN}✓ 嵌入向量生成完成${NC}"
}

# 同步到OpenCode
sync_to_opencode() {
    log "${GREEN}=== 同步到OpenCode ===${NC}"
    
    # 创建符号链接
    ln -sf "$KNOWLEDGE_BASE" "$OPENCODE_DIR/knowledge-base"
    ln -sf "$KNOWLEDGE_BASE/.pawbytes" "$OPENCODE_DIR/pawbytes"
    ln -sf "$KNOWLEDGE_BASE/.pawbytes/marketing-suites" "$OPENCODE_DIR/marketing-suites"
    
    # 同步灏泽和玄门知识库
    ln -sf "$HAOZE_BASE" "$OPENCODE_DIR/haoze-base"
    ln -sf "$XUANMEN_BASE" "$OPENCODE_DIR/xuanmen-base"
    
    log "${GREEN}✓ OpenCode同步完成${NC}"
}

# 显示统计信息
show_stats() {
    log "${GREEN}=== 同步统计 ===${NC}"
    
    # GBrain统计
    echo "GBrain统计:"
    $GBRAIN_CMD stats 2>&1 | head -10
    
    echo ""
    echo "知识库文件数:"
    echo "  道家知识库: $(find "$KNOWLEDGE_BASE" -name "*.md" | wc -l) 个文件"
    echo "  灏泽知识库: $(find "$HAOZE_BASE/正文" -name "*.md" 2>/dev/null | wc -l) 个文件"
    echo "  玄门知识库: $(find "$XUANMEN_BASE/wiki" -name "*.md" 2>/dev/null | wc -l) 个文件"
}

# 主函数
main() {
    log "${GREEN}开始知识库全量同步${NC}"
    log "时间: $(date '+%Y-%m-%d %H:%M:%S')"
    
    check_dependencies
    
    # 选择同步模式
    case "${1:-all}" in
        "all")
            sync_daojia_to_gbrain
            sync_haoze_to_gbrain
            sync_xuanmen_to_gbrain
            generate_embeddings
            sync_to_opencode
            ;;
        "gbrain")
            sync_daojia_to_gbrain
            sync_haoze_to_gbrain
            sync_xuanmen_to_gbrain
            generate_embeddings
            ;;
        "opencode")
            sync_to_opencode
            ;;
        "embed")
            generate_embeddings
            ;;
        *)
            echo "用法: $0 [all|gbrain|opencode|embed]"
            exit 1
            ;;
    esac
    
    show_stats
    
    log "${GREEN}同步完成！${NC}"
}

# 执行主函数
main "$@"
