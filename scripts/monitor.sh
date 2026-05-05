#!/bin/bash
# 知识库监控脚本

echo "=========================================="
echo "   知识库监控"
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

# 1. 知识库文件统计
echo -e "${GREEN}1. 知识库文件统计${NC}"
echo "┌─────────────────────────────────────┐"
echo "│ 知识库           │ 文件数  │ 最后修改 │"
echo "├─────────────────────────────────────┤"

# 道家知识库
daoja_count=$(find "$KNOWLEDGE_BASE" -name "*.md" | wc -l)
daoja_modified=$(find "$KNOWLEDGE_BASE" -name "*.md" -printf '%T+ %p\n' | sort -r | head -1 | cut -d' ' -f1 | cut -d'+' -f1)
echo "│ 道家知识库       │ $daoja_count │ $daoja_modified │"

# 灏泽知识库
haoze_count=$(find "$HAOZE_BASE/正文" -name "*.md" 2>/dev/null | wc -l)
haoze_modified=$(find "$HAOZE_BASE/正文" -name "*.md" -printf '%T+ %p\n' 2>/dev/null | sort -r | head -1 | cut -d' ' -f1 | cut -d'+' -f1)
echo "│ 灏泽知识库       │ $haoze_count │ $haoze_modified │"

# 玄门知识库
xuanmen_count=$(find "$XUANMEN_BASE/wiki" -name "*.md" 2>/dev/null | wc -l)
xuanmen_modified=$(find "$XUANMEN_BASE/wiki" -name "*.md" -printf '%T+ %p\n' 2>/dev/null | sort -r | head -1 | cut -d' ' -f1 | cut -d'+' -f1)
echo "│ 玄门知识库       │ $xuanmen_count │ $xuanmen_modified │"

echo "└─────────────────────────────────────┘"
echo ""

# 2. GBrain状态
echo -e "${GREEN}2. GBrain状态${NC}"
$GBRAIN_CMD stats 2>&1 | head -10
echo ""

# 3. 同步状态
echo -e "${GREEN}3. 同步状态${NC}"
SYNC_STATE_FILE="$KNOWLEDGE_BASE/scripts/.sync_state"
if [ -f "$SYNC_STATE_FILE" ]; then
    last_sync=$(cat "$SYNC_STATE_FILE")
    echo "最后同步时间: $last_sync"
    
    # 计算距离上次同步的时间
    if command -v date &> /dev/null; then
        last_sync_ts=$(date -d "$last_sync" +%s 2>/dev/null || date -j -f "%Y-%m-%d %H:%M:%S" "$last_sync" +%s 2>/dev/null)
        current_ts=$(date +%s)
        diff=$((current_ts - last_sync_ts))
        hours=$((diff / 3600))
        minutes=$(( (diff % 3600) / 60 ))
        echo "距离上次同步: ${hours}小时${minutes}分钟"
    fi
else
    echo "从未同步"
fi
echo ""

# 4. 符号链接状态
echo -e "${GREEN}4. 符号链接状态${NC}"
OPENCODE_DIR="$HOME/.opencode"
for link in knowledge-base pawbytes marketing-suites haoze-base xuanmen-base; do
    if [ -L "$OPENCODE_DIR/$link" ]; then
        target=$(readlink "$OPENCODE_DIR/$link")
        if [ -e "$target" ]; then
            echo -e "  ✓ $link -> $target"
        else
            echo -e "  ${RED}✗ $link -> $target (目标不存在)${NC}"
        fi
    else
        echo -e "  ${YELLOW}⚠ $link 不存在${NC}"
    fi
done
echo ""

# 5. 磁盘空间
echo -e "${GREEN}5. 磁盘空间${NC}"
echo "知识库目录大小:"
du -sh "$KNOWLEDGE_BASE" 2>/dev/null | awk '{print "  道家知识库: "$1}'
du -sh "$HAOZE_BASE" 2>/dev/null | awk '{print "  灏泽知识库: "$1}'
du -sh "$XUANMEN_BASE" 2>/dev/null | awk '{print "  玄门知识库: "$1}'
echo ""

# 6. 最近修改的文件
echo -e "${GREEN}6. 最近修改的文件（前10个）${NC}"
find "$KNOWLEDGE_BASE" -name "*.md" -printf '%T+ %p\n' | sort -r | head -10 | while read line; do
    file=$(echo "$line" | cut -d' ' -f2-)
    time=$(echo "$line" | cut -d' ' -f1 | cut -d'+' -f1)
    echo "  $time $(basename "$file")"
done
echo ""

# 7. 建议
echo -e "${GREEN}7. 建议${NC}"
if [ -f "$SYNC_STATE_FILE" ]; then
    last_sync=$(cat "$SYNC_STATE_FILE")
    last_sync_ts=$(date -d "$last_sync" +%s 2>/dev/null || date -j -f "%Y-%m-%d %H:%M:%S" "$last_sync" +%s 2>/dev/null)
    current_ts=$(date +%s)
    diff=$((current_ts - last_sync_ts))
    hours=$((diff / 3600))
    
    if [ $hours -gt 24 ]; then
        echo -e "  ${YELLOW}⚠ 超过24小时未同步，建议执行全量同步${NC}"
        echo "    运行: ~/文档/道家知识库01/scripts/sync-all.sh all"
    elif [ $hours -gt 6 ]; then
        echo -e "  ${YELLOW}⚠ 超过6小时未同步，建议执行增量同步${NC}"
        echo "    运行: ~/文档/道家知识库01/scripts/sync-incremental.sh"
    else
        echo -e "  ${GREEN}✓ 同步状态良好${NC}"
    fi
else
    echo -e "  ${YELLOW}⚠ 从未同步，建议执行全量同步${NC}"
    echo "    运行: ~/文档/道家知识库01/scripts/sync-all.sh all"
fi
