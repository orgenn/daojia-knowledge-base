#!/bin/bash
# 飞书云盘同步脚本
# 使用lark-cli实现本地知识库与飞书云盘的双向同步

echo "=========================================="
echo "   飞书云盘同步脚本"
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

# 飞书云盘文件夹Token（需要用户配置）
FEISHU_FOLDER_TOKEN="${FEISHU_FOLDER_TOKEN:-}"

# 日志文件
LOG_FILE="$KNOWLEDGE_BASE/scripts/feishu-sync.log"

# 日志函数
log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1" >> "$LOG_FILE"
    echo -e "$1"
}

# 检查配置
check_config() {
    log "${GREEN}=== 检查配置 ===${NC}"
    
    # 检查lark-cli
    if ! command -v lark-cli &> /dev/null; then
        log "${RED}错误: lark-cli未安装${NC}"
        echo "请先安装lark-cli: npm install -g @larksuite/cli"
        exit 1
    fi
    
    # 检查认证状态
    auth_status=$(lark-cli auth status 2>&1)
    if echo "$auth_status" | grep -q "not configured"; then
        log "${RED}错误: lark-cli未配置${NC}"
        echo "请先配置lark-cli: lark-cli config init"
        exit 1
    fi
    
    # 检查文件夹Token
    if [ -z "$FEISHU_FOLDER_TOKEN" ]; then
        log "${YELLOW}警告: 未配置飞书文件夹Token${NC}"
        echo ""
        echo "请设置飞书云盘文件夹Token:"
        echo "  1. 在飞书云盘中创建或选择一个文件夹"
        echo "  2. 从URL中获取folder_token（格式：fldcnXXXXXX）"
        echo "  3. 设置环境变量: export FEISHU_FOLDER_TOKEN=fldcnXXXXXX"
        echo "  4. 或创建配置文件: ~/.feishu-sync.conf"
        echo ""
        
        # 尝试从配置文件读取
        if [ -f "$HOME/.feishu-sync.conf" ]; then
            source "$HOME/.feishu-sync.conf"
            log "${GREEN}从配置文件读取Token${NC}"
        else
            read -p "请输入飞书文件夹Token (fldcnXXXXXX): " FEISHU_FOLDER_TOKEN
            if [ -n "$FEISHU_FOLDER_TOKEN" ]; then
                echo "FEISHU_FOLDER_TOKEN=$FEISHU_FOLDER_TOKEN" > "$HOME/.feishu-sync.conf"
                log "${GREEN}Token已保存到配置文件${NC}"
            else
                log "${RED}错误: 未提供Token${NC}"
                exit 1
            fi
        fi
    fi
    
    log "${GREEN}✓ 配置检查通过${NC}"
    log "  飞书文件夹Token: $FEISHU_FOLDER_TOKEN"
}

# 查看飞书云盘状态
check_feishu_status() {
    log "${GREEN}=== 查看飞书云盘状态 ===${NC}"
    
    # 列出文件夹内容
    echo "飞书云盘文件夹内容:"
    lark-cli drive files list --folder-token "$FEISHU_FOLDER_TOKEN" 2>&1 | head -20
}

# 本地同步到飞书（Push）
push_to_feishu() {
    local local_dir="$1"
    local dir_name="$2"
    
    log "${GREEN}=== 推送 $dir_name 到飞书 ===${NC}"
    log "本地目录: $local_dir"
    
    if [ ! -d "$local_dir" ]; then
        log "${RED}错误: 目录不存在 - $local_dir${NC}"
        return 1
    fi
    
    # 先检查状态
    echo "检查差异..."
    lark-cli drive +push \
        --folder-token "$FEISHU_FOLDER_TOKEN" \
        --local-dir "$local_dir" \
        --if-exists skip \
        --dry-run 2>&1 | head -20
    
    echo ""
    read -p "确认推送？(y/N): " confirm
    if [ "$confirm" = "y" ] || [ "$confirm" = "Y" ]; then
        # 执行推送
        lark-cli drive +push \
            --folder-token "$FEISHU_FOLDER_TOKEN" \
            --local-dir "$local_dir" \
            --if-exists skip \
            2>&1 | tee -a "$LOG_FILE"
        
        log "${GREEN}✓ $dir_name 推送完成${NC}"
    else
        log "${YELLOW}已取消推送${NC}"
    fi
}

# 飞书同步到本地（Pull）
pull_from_feishu() {
    local local_dir="$1"
    local dir_name="$2"
    
    log "${GREEN}=== 从飞书拉取 $dir_name ===${NC}"
    log "本地目录: $local_dir"
    
    # 先检查状态
    echo "检查差异..."
    lark-cli drive +pull \
        --folder-token "$FEISHU_FOLDER_TOKEN" \
        --local-dir "$local_dir" \
        --if-exists skip \
        --dry-run 2>&1 | head -20
    
    echo ""
    read -p "确认拉取？(y/N): " confirm
    if [ "$confirm" = "y" ] || [ "$confirm" = "Y" ]; then
        # 执行拉取
        lark-cli drive +pull \
            --folder-token "$FEISHU_FOLDER_TOKEN" \
            --local-dir "$local_dir" \
            --if-exists skip \
            2>&1 | tee -a "$LOG_FILE"
        
        log "${GREEN}✓ $dir_name 拉取完成${NC}"
    else
        log "${YELLOW}已取消拉取${NC}"
    fi
}

# 双向同步
bidirectional_sync() {
    local local_dir="$1"
    local dir_name="$2"
    
    log "${GREEN}=== 双向同步 $dir_name ===${NC}"
    log "本地目录: $local_dir"
    
    # 先检查状态
    echo "检查差异..."
    lark-cli drive status \
        --folder-token "$FEISHU_FOLDER_TOKEN" \
        --local-dir "$local_dir" \
        2>&1 | head -30
    
    echo ""
    echo "选择同步方向:"
    echo "1) 本地 → 飞书 (Push)"
    echo "2) 飞书 → 本地 (Pull)"
    echo "3) 双向同步 (先Pull后Push)"
    echo "4) 取消"
    read -p "请选择 [1-4]: " choice
    
    case $choice in
        1)
            push_to_feishu "$local_dir" "$dir_name"
            ;;
        2)
            pull_from_feishu "$local_dir" "$dir_name"
            ;;
        3)
            log "${GREEN}执行双向同步...${NC}"
            # 先拉取飞书的更新
            lark-cli drive +pull \
                --folder-token "$FEISHU_FOLDER_TOKEN" \
                --local-dir "$local_dir" \
                --if-exists skip \
                2>&1 | tee -a "$LOG_FILE"
            # 再推送本地的更新
            lark-cli drive +push \
                --folder-token "$FEISHU_FOLDER_TOKEN" \
                --local-dir "$local_dir" \
                --if-exists skip \
                2>&1 | tee -a "$LOG_FILE"
            log "${GREEN}✓ 双向同步完成${NC}"
            ;;
        4)
            log "${YELLOW}已取消同步${NC}"
            ;;
    esac
}

# 创建飞书文件夹结构
create_feishu_structure() {
    log "${GREEN}=== 创建飞书文件夹结构 ===${NC}"
    
    # 创建主文件夹
    echo "创建主文件夹: 道家知识库"
    lark-cli drive +create-folder \
        --name "道家知识库" \
        --folder-token "$FEISHU_FOLDER_TOKEN" \
        2>&1 | tee -a "$LOG_FILE"
    
    # 创建子文件夹
    for subdir in "01-核心概念" "02-商业运营" "03-教育内容" "04-合规规范" "05-项目资料" "06-角色设定" "07-经典书籍" "08-LLM-Wiki知识管理" "基础RAW"; do
        echo "创建子文件夹: $subdir"
        lark-cli drive +create-folder \
            --name "$subdir" \
            --folder-token "$FEISHU_FOLDER_TOKEN" \
            2>&1 | tee -a "$LOG_FILE"
    done
    
    log "${GREEN}✓ 文件夹结构创建完成${NC}"
}

# 主菜单
show_menu() {
    echo ""
    echo -e "${GREEN}飞书云盘同步菜单${NC}"
    echo "=========================================="
    echo "1) 查看飞书云盘状态"
    echo "2) 推送道家知识库到飞书"
    echo "3) 从飞书拉取道家知识库"
    echo "4) 双向同步道家知识库"
    echo "5) 推送灏泽知识库到飞书"
    echo "6) 推送玄门知识库到飞书"
    echo "7) 创建飞书文件夹结构"
    echo "8) 全量同步（所有知识库）"
    echo "9) 退出"
    echo ""
    read -p "请选择 [1-9]: " choice
    
    case $choice in
        1)
            check_feishu_status
            ;;
        2)
            push_to_feishu "$KNOWLEDGE_BASE" "道家知识库"
            ;;
        3)
            pull_from_feishu "$KNOWLEDGE_BASE" "道家知识库"
            ;;
        4)
            bidirectional_sync "$KNOWLEDGE_BASE" "道家知识库"
            ;;
        5)
            push_to_feishu "$HAOZE_BASE" "灏泽知识库"
            ;;
        6)
            push_to_feishu "$XUANMEN_BASE" "玄门知识库"
            ;;
        7)
            create_feishu_structure
            ;;
        8)
            log "${GREEN}=== 全量同步 ===${NC}"
            push_to_feishu "$KNOWLEDGE_BASE" "道家知识库"
            push_to_feishu "$HAOZE_BASE" "灏泽知识库"
            push_to_feishu "$XUANMEN_BASE" "玄门知识库"
            ;;
        9)
            log "${GREEN}退出${NC}"
            exit 0
            ;;
        *)
            echo "无效选择"
            ;;
    esac
}

# 主函数
main() {
    check_config
    
    while true; do
        show_menu
        echo ""
        read -p "按Enter继续..."
    done
}

# 执行主函数
main
