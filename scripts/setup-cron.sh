#!/bin/bash
# 设置定时同步任务

echo "=========================================="
echo "   设置定时同步任务"
echo "=========================================="
echo ""

# 颜色定义
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

# 脚本路径
SYNC_SCRIPT="$HOME/文档/道家知识库01/scripts/sync-all.sh"
INCREMENTAL_SCRIPT="$HOME/文档/道家知识库01/scripts/sync-incremental.sh"

# 显示当前cron任务
echo -e "${GREEN}当前cron任务:${NC}"
crontab -l 2>/dev/null | grep -E "sync|知识库" || echo "  无相关任务"
echo ""

# 添加定时任务
echo -e "${GREEN}选择同步频率:${NC}"
echo "1) 每小时增量同步"
echo "2) 每天全量同步（凌晨2点）"
echo "3) 每周全量同步（周日凌晨3点）"
echo "4) 自定义"
echo "5) 查看当前任务"
echo "6) 删除所有同步任务"
echo ""
read -p "请选择 [1-6]: " choice

case $choice in
    1)
        # 每小时增量同步
        (crontab -l 2>/dev/null; echo "0 * * * * $INCREMENTAL_SCRIPT >> $HOME/文档/道家知识库01/scripts/cron.log 2>&1") | crontab -
        echo -e "${GREEN}✓ 已添加每小时增量同步${NC}"
        ;;
    2)
        # 每天全量同步
        (crontab -l 2>/dev/null; echo "0 2 * * * $SYNC_SCRIPT all >> $HOME/文档/道家知识库01/scripts/cron.log 2>&1") | crontab -
        echo -e "${GREEN}✓ 已添加每天凌晨2点全量同步${NC}"
        ;;
    3)
        # 每周全量同步
        (crontab -l 2>/dev/null; echo "0 3 * * 0 $SYNC_SCRIPT all >> $HOME/文档/道家知识库01/scripts/cron.log 2>&1") | crontab -
        echo -e "${GREEN}✓ 已添加每周日凌晨3点全量同步${NC}"
        ;;
    4)
        # 自定义
        read -p "输入cron表达式 (例如: 0 */2 * * *): " cron_expr
        read -p "选择同步类型 (all/gbrain/opencode/embed): " sync_type
        (crontab -l 2>/dev/null; echo "$cron_expr $SYNC_SCRIPT $sync_type >> $HOME/文档/道家知识库01/scripts/cron.log 2>&1") | crontab -
        echo -e "${GREEN}✓ 已添加自定义同步任务${NC}"
        ;;
    5)
        # 查看当前任务
        echo -e "${GREEN}当前cron任务:${NC}"
        crontab -l 2>/dev/null | grep -E "sync|知识库"
        ;;
    6)
        # 删除所有同步任务
        crontab -l 2>/dev/null | grep -v -E "sync|知识库" | crontab -
        echo -e "${GREEN}✓ 已删除所有同步任务${NC}"
        ;;
    *)
        echo "无效选择"
        exit 1
        ;;
esac

echo ""
echo -e "${GREEN}当前cron任务:${NC}"
crontab -l 2>/dev/null | grep -E "sync|知识库" || echo "  无"
