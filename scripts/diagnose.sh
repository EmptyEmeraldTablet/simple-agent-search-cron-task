#!/bin/bash
# 错误处理与恢复脚本
# 用于手动运行失败后的诊断和恢复

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DATA_DIR="$SCRIPT_DIR/data"
LOG_DIR="$SCRIPT_DIR/logs"

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

echo -e "${YELLOW}=== 定时任务诊断与恢复工具 ===${NC}"
echo ""

# 检查 opencode 是否可用
check_opencode() {
    echo -e "${YELLOW}[1/6] 检查 opencode 安装...${NC}"
    if command -v opencode &> /dev/null; then
        version=$(opencode --version 2>&1 || echo "未知")
        echo -e "${GREEN}✓ opencode 已安装: $version${NC}"
        return 0
    else
        echo -e "${RED}✗ opencode 未安装${NC}"
        echo "  安装方法: curl -fsSL https://opencode.ai/install | bash"
        return 1
    fi
}

# 检查配置文件
check_config() {
    echo ""
    echo -e "${YELLOW}[2/6] 检查配置文件...${NC}"
    local config_file="$SCRIPT_DIR/config/config.json"
    
    if [ -f "$config_file" ]; then
        echo -e "${GREEN}✓ 配置文件存在${NC}"
        echo "  关键词:"
        jq -r '.searchKeywords[]' "$config_file" 2>/dev/null | sed 's/^/    - /'
        return 0
    else
        echo -e "${RED}✗ 配置文件不存在: $config_file${NC}"
        return 1
    fi
}

# 检查数据目录
check_data() {
    echo ""
    echo -e "${YELLOW}[3/6] 检查数据目录...${NC}"
    
    # 创建必要的目录和文件
    mkdir -p "$DATA_DIR" "$LOG_DIR"
    
    if [ -f "$DATA_DIR/content_registry.json" ]; then
        local count=$(jq '.entries | length' "$DATA_DIR/content_registry.json" 2>/dev/null || echo "0")
        echo -e "${GREEN}✓ 内容注册表存在 (共 $count 条记录)${NC}"
    else
        echo -e "${YELLOW}! 内容注册表不存在，已创建空表${NC}"
        echo '{"version": "1.0", "taskName": "技术创新监测", "lastUpdated": null, "entries": []}' > "$DATA_DIR/content_registry.json"
    fi
    
    if [ -f "$DATA_DIR/summary_latest.md" ]; then
        echo -e "${GREEN}✓ 摘要文件存在${NC}"
    else
        echo -e "${YELLOW}! 摘要文件不存在，已创建${NC}"
        cat > "$DATA_DIR/summary_latest.md" << 'EOF'
## 摘要

暂无历史摘要。

## 内容指纹

无
EOF
    fi
    
    return 0
}

# 检查日志
check_logs() {
    echo ""
    echo -e "${YELLOW}[4/6] 检查日志文件...${NC}"
    
    if [ -f "$LOG_DIR/summary.log" ]; then
        local lines=$(wc -l < "$LOG_DIR/summary.log")
        echo -e "${GREEN}✓ 详细日志存在 ($lines 行)${NC}"
        echo "  最近 5 条记录:"
        tail -5 "$LOG_DIR/summary.log" | sed 's/^/    /'
    else
        echo -e "${YELLOW}! 详细日志不存在${NC}"
    fi
    
    if [ -f "$LOG_DIR/error.log" ]; then
        local error_lines=$(wc -l < "$LOG_DIR/error.log")
        echo -e "${YELLOW}! 错误日志存在 ($error_lines 条错误)${NC}"
        echo "  最近 5 条错误:"
        tail -5 "$LOG_DIR/error.log" | sed 's/^/    /'
    fi
    
    return 0
}

# 检查锁文件
check_lock() {
    echo ""
    echo -e "${YELLOW}[5/6] 检查锁文件...${NC}"
    
    local lock_file="$LOG_DIR/running.lock"
    
    if [ -f "$lock_file" ]; then
        local pid=$(cat "$lock_file")
        if kill -0 "$pid" 2>/dev/null; then
            echo -e "${RED}✗ 任务正在运行中 (PID: $pid)${NC}"
            echo "  如确认任务已停止，手动删除: rm $lock_file"
            return 1
        else
            echo -e "${YELLOW}! 发现 stale lock 文件，已删除${NC}"
            rm -f "$lock_file"
        fi
    else
        echo -e "${GREEN}✓ 无锁文件，任务未在运行${NC}"
    fi
    
    return 0
}

# 测试运行
test_run() {
    echo ""
    echo -e "${YELLOW}[6/6] 测试运行任务...${NC}"
    echo "  (将运行 30 秒超时测试)"
    
    read -p "是否执行测试运行? (y/n): " confirm
    if [ "$confirm" != "y" ]; then
        echo "已跳过测试"
        return 0
    fi
    
    local test_script="$SCRIPT_DIR/scripts/cron-search.sh"
    if [ -f "$test_script" ]; then
        timeout 30 bash "$test_script" || echo "  (测试超时或执行完成)"
    else
        echo -e "${RED}✗ 脚本不存在: $test_script${NC}"
    fi
}

# 清理功能
cleanup() {
    echo ""
    echo -e "${YELLOW}=== 清理选项 ===${NC}"
    echo "1. 清理锁文件"
    echo "2. 清理错误日志"
    echo "3. 清理历史记录（重新开始）"
    echo "4. 清理所有日志和数据"
    echo "0. 退出"
    
    read -p "请选择: " choice
    
    case $choice in
        1)
            rm -f "$LOG_DIR/running.lock"
            echo -e "${GREEN}✓ 锁文件已清理${NC}"
            ;;
        2)
            rm -f "$LOG_DIR/error.log"
            echo -e "${GREEN}✓ 错误日志已清理${NC}"
            ;;
        3)
            echo '{"version": "1.0", "taskName": "技术创新监测", "lastUpdated": null, "entries": []}' > "$DATA_DIR/content_registry.json"
            cat > "$DATA_DIR/summary_latest.md" << 'EOF'
## 摘要

暂无历史摘要。

## 内容指纹

无
EOF
            echo -e "${GREEN}✓ 历史记录已清理${NC}"
            ;;
        4)
            rm -f "$LOG_DIR/"*.log
            echo '{"version": "1.0", "taskName": "技术创新监测", "lastUpdated": null, "entries": []}' > "$DATA_DIR/content_registry.json"
            cat > "$DATA_DIR/summary_latest.md" << 'EOF'
## 摘要

暂无历史摘要。

## 内容指纹

无
EOF
            echo -e "${GREEN}✓ 所有日志和数据已清理${NC}"
            ;;
        *)
            echo "已退出"
            ;;
    esac
}

# 手动执行
manual_run() {
    echo ""
    echo -e "${YELLOW}=== 手动执行任务 ===${NC}"
    
    local script="$SCRIPT_DIR/scripts/cron-search.sh"
    if [ -f "$script" ]; then
        bash "$script"
    else
        echo -e "${RED}✗ 脚本不存在: $script${NC}"
    fi
}

# 菜单
show_menu() {
    echo ""
    echo -e "${YELLOW}=== 菜单 ===${NC}"
    echo "1. 诊断检查"
    echo "2. 手动执行任务"
    echo "3. 清理功能"
    echo "4. 测试运行"
    echo "0. 退出"
    
    read -p "请选择: " choice
    
    case $choice in
        1)
            check_opencode
            check_config
            check_data
            check_logs
            check_lock
            ;;
        2)
            manual_run
            ;;
        3)
            cleanup
            ;;
        4)
            test_run
            ;;
        0)
            echo "再见!"
            exit 0
            ;;
        *)
            echo "无效选择"
            ;;
    esac
}

# 主流程
main() {
    check_opencode || exit 1
    check_config || exit 1
    check_data
    check_logs
    check_lock
    
    # 如果一切正常，询问是否执行
    show_menu
}

main "$@"
