#!/bin/bash
# 模拟 opencode run 脚本
# 用于测试流程，不实际调用 AI
# 运行约 1 分钟后完成

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"
DATA_DIR="$PROJECT_ROOT/data"
LOG_DIR="$PROJECT_ROOT/logs"
CONFIG_FILE="$PROJECT_ROOT/config/config.json"

LOG_FILE="$LOG_DIR/summary.log"
ERROR_LOG="$LOG_DIR/error.log"

MOCK_DELAY=60  # 模拟运行时间（秒）

log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] [模拟] $*" | tee -a "$LOG_FILE"
}

log "========== 模拟技术创新监测任务开始 =========="
log "接收到的提示词长度: ${#1} 字符"

# 模拟搜索过程
log "开始模拟多关键词搜索..."

# 读取配置中的关键词
if [ -f "$CONFIG_FILE" ]; then
    KEYWORDS=$(jq -r '.searchKeywords | join(", ")' "$CONFIG_FILE" 2>/dev/null || echo "未知")
    log "搜索关键词: $KEYWORDS"
fi

# 模拟每个关键词的搜索（每个间隔几秒）
KEYWORD_LIST=$(jq -r '.searchKeywords[]' "$CONFIG_FILE" 2>/dev/null || echo "")
for i in {1..3}; do
    log "  模拟搜索关键词 $i/5..."
    sleep 2
done

log "搜索完成，找到 12 条结果"

# 模拟去重检查
log "执行去重检查..."
sleep 2
log "发现 3 条新内容"

# 模拟生成报告
log "生成分析报告..."
sleep 2

# 写入模拟数据
TIMESTAMP=$(date -Iseconds)

# 更新 content_registry.json
REGISTRY_FILE="$DATA_DIR/content_registry.json"

# 确保文件存在且有效
if [ ! -s "$REGISTRY_FILE" ]; then
    cat > "$REGISTRY_FILE" << 'EOF'
{
  "version": "1.0",
  "taskName": "技术创新监测",
  "lastUpdated": null,
  "entries": []
}
EOF
fi

# 添加模拟数据
jq --arg timestamp "$TIMESTAMP" '
    if type == "array" then
        {version: "1.0", taskName: "技术创新监测", lastUpdated: $timestamp, entries: .}
    else
        .lastUpdated = $timestamp
    end
    | .entries += [
        {
            "title": "Mock Project: AI Agent Framework",
            "url": "https://github.com/mock/ai-agent-framework",
            "source": "github",
            "keywords": ["AI", "agent"],
            "addedAt": $timestamp
        },
        {
            "title": "Mock Paper: Transformer Advances",
            "url": "https://arxiv.org/abs/2601.12345",
            "source": "arxiv",
            "keywords": ["transformer", "ML"],
            "addedAt": $timestamp
        },
        {
            "title": "Mock Discussion: New Programming Paradigm",
            "url": "https://reddit.com/r/programming/comments/mock123",
            "source": "reddit",
            "keywords": ["programming"],
            "addedAt": $timestamp
        }
    ]
' "$REGISTRY_FILE" > "$REGISTRY_FILE.tmp" && mv "$REGISTRY_FILE.tmp" "$REGISTRY_FILE"

log "已更新 content_registry.json"

# 写入摘要
cat > "$DATA_DIR/summary_latest.md" << EOF
## 摘要

本期监测发现 3 个技术创新内容：
1. GitHub: AI Agent Framework - 新兴开源框架
2. arXiv: Transformer Advances - 学术研究进展
3. Reddit: New Programming Paradigm - 社区讨论

## 内容指纹

Mock Project: AI Agent Framework|https://github.com/mock/ai-agent-framework, Mock Paper: Transformer Advances|https://arxiv.org/abs/2601.12345, Mock Discussion: New Programming Paradigm|https://reddit.com/r/programming/comments/mock123
EOF

log "已更新 summary_latest.md"

# 模拟完成
log "========== 模拟任务完成 =========="
log "实际耗时: ${MOCK_DELAY} 秒"
log "模拟执行成功"

exit 0
