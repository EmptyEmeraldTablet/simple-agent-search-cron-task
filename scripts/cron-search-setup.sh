#!/bin/bash
# Cron 任务自动设置脚本
# 用法: ./cron-search-setup.sh

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CRON_SCRIPT="$SCRIPT_DIR/cron-search.sh"
LOG_FILE="$(dirname "$SCRIPT_DIR")/logs/cron-cron-search.log"

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

echo -e "${YELLOW}=== 定时任务设置向导 ===${NC}"
echo ""

# 检查脚本是否存在
if [ ! -f "$CRON_SCRIPT" ]; then
    echo -e "${RED}错误: 脚本不存在: $CRON_SCRIPT${NC}"
    exit 1
fi

# 检查执行权限
if [ ! -x "$CRON_SCRIPT" ]; then
    echo "添加执行权限..."
    chmod +x "$CRON_SCRIPT"
fi

# 选择执行频率
echo "请选择执行频率:"
echo "1. 每天早上 8:00"
echo "2. 每天早上 8:00 和 晚上 20:00"
echo "3. 每 2 小时"
echo "4. 每小时"
echo "5. 每 5 分钟（测试用）"
echo "6. 自定义 cron 表达式"
echo ""

read -p "请选择 (1-6): " choice

case $choice in
    1)
        CRON_EXPR="0 8 * * *"
        DESC="每天早上 8:00"
        ;;
    2)
        CRON_EXPR="0 8,20 * * *"
        DESC="每天 8:00 和 20:00"
        ;;
    3)
        CRON_EXPR="0 */2 * * *"
        DESC="每 2 小时"
        ;;
    4)
        CRON_EXPR="0 * * * *"
        DESC="每小时"
        ;;
    5)
        CRON_EXPR="*/5 * * * *"
        DESC="每 5 分钟"
        ;;
    6)
        read -p "请输入 cron 表达式 (例如: 0 9 * * 1): " CRON_EXPR
        DESC="自定义: $CRON_EXPR"
        ;;
    *)
        echo "无效选择"
        exit 1
        ;;
esac

echo ""
echo "选择的执行时间: $DESC"
echo "Cron 表达式: $CRON_EXPR"
echo ""

# 确保日志目录存在
mkdir -p "$(dirname "$LOG_FILE")"

# 构建 cron 行
CRON_LINE="$CRON_EXPR $CRON_SCRIPT >> $LOG_FILE 2>&1"

echo "将要添加的 cron 任务:"
echo "$CRON_LINE"
echo ""

read -p "确认添加? (y/n): " confirm
if [ "$confirm" != "y" ]; then
    echo "已取消"
    exit 0
fi

# 添加 cron 任务
# 先删除旧的同名任务（如果存在）
TEMP_CRON=$(mktemp)
crontab -l 2>/dev/null | grep -v "$CRON_SCRIPT" > "$TEMP_CRON" || true
echo "$CRON_LINE" >> "$TEMP_CRON"
crontab "$TEMP_CRON"
rm -f "$TEMP_CRON"

echo ""
echo -e "${GREEN}✓ cron 任务已添加!${NC}"
echo ""

# 验证
echo "当前 cron 任务列表:"
crontab -l

echo ""
echo -e "${YELLOW}提示:${NC}"
echo "- 查看日志: tail -f $LOG_FILE"
echo "- 手动执行: $CRON_SCRIPT"
echo "- 诊断问题: cd $SCRIPT_DIR && ./diagnose.sh"
echo ""
echo -e "${GREEN}设置完成!${NC}"
