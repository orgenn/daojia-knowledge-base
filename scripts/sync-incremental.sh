#!/bin/bash
# 知识库增量同步脚本
# 只同步修改过的文件

echo "=========================================="
echo "   知识库增量同步脚本"
echo "=========================================="
echo ""

# 颜色定义
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

# 路径配置
KNOWLEDGE_BASE="$HOME/文档/道家知识库01"
GBRAIN_CMD="$HOME/.bun/bin/gbrain"
SYNC_STATE_FILE="$KNOWLEDGE_BASE/scripts/.sync_state"

# 获取上次同步时间
get_last_sync() {
    if [ -f "$SYNC_STATE_FILE" ]; then
        cat "$SYNC_STATE_FILE"
    else
        echo "1970-01-01 00:00:00"
    fi
}

# 保存同步状态
save_sync_state() {
    date '+%Y-%m-%d %H:%M:%S' > "$SYNC_STATE_FILE"
}

# 查找修改过的文件
find_modified_files() {
    local since="$1"
    local dir="$2"
    
    find "$dir" -name "*.md" -newer <(date -d "$since" '+%Y%m%d%H%M.%S' 2>/dev/null || date -d "$since" '+%Y-%m-%d %H:%M:%S') 2>/dev/null
}

# 同步修改过的文件
sync_modified_files() {
    local since="$1"
    
    echo -e "${GREEN}查找 $since 之后修改的文件...${NC}"
    
    # 道家知识库
    echo "道家知识库:"
    local daoja_files=$(find_modified_files "$since" "$KNOWLEDGE_BASE")
    if [ -n "$daoja_files" ]; then
        echo "$daoja_files" | while read file; do
            echo "  - $(basename "$file")"
        done
        # 导入修改过的文件
        echo "$daoja_files" | xargs -I {} $GBRAIN_CMD import {} --no-embed 2>/dev/null
    else
        echo "  无修改"
    fi
    
    # 灏泽知识库
    echo "灏泽知识库:"
    local haoze_files=$(find_modified_files "$since" "$HOME/文档/haoze/正文")
    if [ -n "$haoze_files" ]; then
        echo "$haoze_files" | wc -l
        echo "  个文件已修改"
    else
        echo "  无修改"
    fi
    
    # 玄门知识库
    echo "玄门知识库:"
    local xuanmen_files=$(find_modified_files "$since" "$HOME/文档/xuanmen/wiki")
    if [ -n "$xuanmen_files" ]; then
        echo "$xuanmen_files" | wc -l
        echo "  个文件已修改"
    else
        echo "  无修改"
    fi
}

# 主函数
main() {
    local last_sync=$(get_last_sync)
    
    echo -e "${GREEN}上次同步时间: $last_sync${NC}"
    echo ""
    
    # 同步修改过的文件
    sync_modified_files "$last_sync"
    
    # 生成嵌入
    echo ""
    echo -e "${GREEN}生成嵌入向量...${NC}"
    $GBRAIN_CMD embed --stale 2>&1 | tail -3
    
    # 保存同步状态
    save_sync_state
    
    echo ""
    echo -e "${GREEN}增量同步完成！${NC}"
}

main
