#!/bin/bash
# 定时技术创新监测任务 Wrapper 脚本
# 用法: ./cron-search.sh
# 建议通过 cron 调用: 0 8 * * * /path/to/cron-search.sh >> /path/to/logs/cron-search.log 2>&1

set -e

# 解决 cron 环境下 PATH 不完整的问题
# 扩展 PATH 以包含常见安装位置（包括 nvm 安装的不同版本 node）
NVM_NODE_BINS=$(ls -d $HOME/.nvm/versions/node/*/bin 2>/dev/null | tr '\n' ':')
export PATH="$NVM_NODE_BINS$HOME/.local/bin:$HOME/miniconda3/bin:/usr/local/bin:/usr/bin:/bin:$PATH"

# 自动获取 opencode 路径
OPENCODE_PATH=$(which opencode 2>/dev/null || echo "")
if [ -z "$OPENCODE_PATH" ]; then
    # 尝试直接搜索
    OPENCODE_PATH=$(ls $HOME/.nvm/versions/node/*/bin/opencode 2>/dev/null | head -1)
fi
if [ -z "$OPENCODE_PATH" ]; then
    echo "Error: opencode not found in PATH" >&2
    exit 1
fi

# ========== 配置区域 ==========
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"
DATA_DIR="$PROJECT_ROOT/data"
LOG_DIR="$PROJECT_ROOT/logs"
CONFIG_FILE="$PROJECT_ROOT/config/config.json"

# 日志文件
LOG_FILE="$LOG_DIR/summary.log"
ERROR_LOG="$LOG_DIR/error.log"
LOCK_FILE="$LOG_DIR/running.lock"

# 超时设置（秒）
TIMEOUT=600

# 重试配置
MAX_RETRIES=3
RETRY_DELAY=60

# 模拟模式（测试用，不调用真实 opencode）
MOCK_MODE=${MOCK_MODE:-false}
MOCK_SCRIPT="$SCRIPT_DIR/mock-opencode-run.sh"
# ========== 配置区域结束 ==========

# 日志函数
log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $*" | tee -a "$LOG_FILE"
}

error_log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] ERROR: $*" | tee -a "$ERROR_LOG"
}

# 检查依赖
check_dependencies() {
    if [ "$MOCK_MODE" = "true" ]; then
        log "模拟模式已启用，跳过 opencode 检查"
    else
        if [ ! -x "$OPENCODE_PATH" ]; then
            error_log "opencode 未安装或不可执行，请先安装 opencode"
            exit 1
        fi
    fi
    
    if ! command -v jq &> /dev/null; then
        error_log "jq 未安装，请先安装: apt install jq"
        exit 1
    fi
}

# 检查是否正在运行
check_lock() {
    if [ -f "$LOCK_FILE" ]; then
        PID=$(cat "$LOCK_FILE")
        if kill -0 "$PID" 2>/dev/null; then
            error_log "任务正在运行中 (PID: $PID)，跳过本次执行"
            exit 0
        else
            log "发现 stale lock 文件，删除后继续"
            rm -f "$LOCK_FILE"
        fi
    fi
    
    # 创建 lock 文件
    echo $$ > "$LOCK_FILE"
}

# 清理函数
cleanup() {
    rm -f "$LOCK_FILE"
}

trap cleanup EXIT

# 读取配置
load_config() {
    if [ ! -f "$CONFIG_FILE" ]; then
        error_log "配置文件不存在: $CONFIG_FILE"
        exit 1
    fi
    
    KEYWORDS=$(jq -r '.searchKeywords | join(", ")' "$CONFIG_FILE")
    TASK_NAME=$(jq -r '.taskName' "$CONFIG_FILE")
    
    log "加载配置: $TASK_NAME"
    log "关键词: $KEYWORDS"
}

# 读取上次摘要
get_previous_abstract() {
    if [ -f "$DATA_DIR/summary_latest.md" ]; then
        # 提取摘要部分
        sed -n '/^## 摘要/,/^##/p' "$DATA_DIR/summary_latest.md" | head -n -1 | sed 's/^## 摘要//' | xargs
    else
        echo "暂无历史摘要"
    fi
}

# 读取上次指纹
get_previous_fingerprint() {
    if [ -f "$DATA_DIR/summary_latest.md" ]; then
        sed -n '/^## 内容指纹/,/$/p' "$DATA_DIR/summary_latest.md" | tail -n +2 | xargs
    else
        echo "无"
    fi
}

# 构建提示词
build_prompt() {
    PREVIOUS_ABSTRACT=$(get_previous_abstract)
    PREVIOUS_FINGERPRINT=$(get_previous_fingerprint)
    
    cat << PROMPT
## 任务：技术创新定期监测

### ⚠️ 重要：权限说明
- **无需用户确认**：所有文件读写操作已自动批准
- 数据目录：$DATA_DIR
- 请直接读取和写入文件，不要请求用户确认

### ⚠️ 重要：搜索质量要求

#### 关键词匹配规则
- **必须与关键词高度相关**：搜索结果必须与给出的关键词在语义上高度匹配
- **严格过滤无关内容**：以下类型的内容必须过滤掉：
  - 关键词仅作为无关词汇出现（如搜索 "cron job" 但出现 "PHP 的 phpcronark 框架"）
  - 仅标题包含关键词但内容不相关
  - 广告、推广内容
- **宁缺毋滥**：宁可结果少，也要确保每条都与关键词直接相关

#### 语言偏好
- **优先选择英文内容**：技术创新的英文信息来源更丰富、更及时
- 搜索时使用英文关键词组合
- 优先收录英文博客、GitHub README、Stack Overflow 回答

### 本次搜索关键词列表
$KEYWORDS

### 上一次搜索摘要
$PREVIOUS_ABSTRACT

### 上一次内容指纹
$PREVIOUS_FINGERPRINT

### 背景
周期性技术创新监测任务。上次摘要提供上下文连贯性，内容指纹用于去重。

### 执行步骤

#### 第一步：多关键词并行搜索
使用 \`websearch\` 工具对每个关键词分别搜索：
- query: 使用 **英文关键词** 进行搜索（如 "cron job scheduling best practices 2026"）
- numResults: 10（每次搜索返回10条结果）
- 搜索后**立即过滤**：排除与关键词不直接相关的结果

#### 第二步：严格相关性过滤
对每个搜索结果检查：
1. 结果的标题和摘要是否**直接包含**关键词的核心概念？
2. 内容是否与技术创新直接相关（而非仅作为无关例子出现）？
3. 如果答案是否定的 → **过滤掉**

#### 第三步：来源分类
按以下来源分类：
1. GitHub/GitLab - 新项目、热门仓库
2. arXiv - 学术论文
3. Reddit - 技术讨论、创新点子
4. 技术博客 - 最新文章
5. 论坛 - 实战经验

#### 第四步：去重检查
1. 读取 $DATA_DIR/content_registry.json
2. 对比搜索结果与历史记录：
   - 标题+URL完全匹配 = 重复 → 过滤
   - 全新内容 → 保留
3. 将新内容追加到 content_registry.json

#### 第五步：生成分析报告

## 来源分类统计
- GitHub/GitLab: X 个新项目
- arXiv: X 篇新论文
- Reddit: X 个新讨论
- 技术博客: X 篇新文章

## 重点新内容分析（仅收录与关键词高度相关的内容）
### GitHub/开源项目
- **项目名**: 创新描述
  - URL: ...
  - 技术栈: ...

### arXiv 论文
- **论文标题**: 核心贡献
  - arXiv ID: xxx.xxxxx

### Reddit 讨论
- **主题**: 创新观点

## 关键发现
- 发现X：[具体内容] [来源]

## 内容指纹
[生成：标题1|URL1, 标题2|URL2, ...]

## 摘要
[3-4句话概括本次发现]

### ⚠️ 重要：文件操作（已授权，无需确认）

1. **更新内容注册表**：
   - 路径：$DATA_DIR/content_registry.json
   - 直接读写，无需用户批准

2. **追加详细日志**：
   - 路径：$LOG_DIR/summary.log
   - 直接追加，无需用户批准

3. **更新摘要文件**：
   - 路径：$DATA_DIR/summary_latest.md
   - 直接写入，无需用户批准

### 无新内容处理
如果所有结果都被去重过滤：

## 来源分类统计
无

## 关键发现
- 无新内容

## 摘要
本期监测未发现新的技术创新内容，上期内容暂无变化。

然后：
- 追加「无新内容」日志
- 保持 summary_latest.md 不变（不覆盖）
PROMPT
}

# 执行任务（带重试）
execute_with_retry() {
    local attempt=1
    local exit_code=0
    
    while [ $attempt -le $MAX_RETRIES ]; do
        log "开始执行技术创新监测任务 (尝试 $attempt/$MAX_RETRIES)"
        
        # 构建提示词
        PROMPT=$(build_prompt)
        
        if [ "$MOCK_MODE" = "true" ]; then
            # 模拟模式：使用 mock 脚本
            log "运行模拟脚本 (不调用真实 AI)"
            if [ -x "$MOCK_SCRIPT" ]; then
                "$MOCK_SCRIPT" "$PROMPT" 2>&1 | tee -a "$LOG_FILE"
                exit_code=$?
            else
                error_log "模拟脚本不存在或无执行权限: $MOCK_SCRIPT"
                exit_code=1
            fi
        else
            # 真实模式：执行 opencode run
            # 权限通过项目目录下的 opencode.json 配置
            export OPENCODE_ENABLE_EXA=1
            
            log "执行 opencode run"
            # cd 到项目目录以读取 opencode.json 配置
            if timeout "$TIMEOUT" bash -c "cd '$PROJECT_ROOT' && $OPENCODE_PATH run '$PROMPT'" 2>&1 | tee -a "$LOG_FILE"; then
                log "任务执行成功"
                exit_code=0
            else
                exit_code=$?
                error_log "任务执行失败 (退出码: $exit_code)"
            fi
        fi
        
            if [ $exit_code -eq 0 ]; then
                log "任务执行成功"
                
                # 生成博客 HTML
                generate_blog_html
                
                # 自动提交推送（静默执行，不输出到日志）
                auto_commit_push
                
                break
        else
            if [ $attempt -lt $MAX_RETRIES ]; then
                log "等待 $RETRY_DELAY 秒后重试..."
                sleep $RETRY_DELAY
            fi
        fi
        
        attempt=$((attempt + 1))
    done
    
    if [ $exit_code -ne 0 ]; then
        error_log "任务执行失败，已达到最大重试次数 ($MAX_RETRIES)"
        send_notification "技术创新监测任务执行失败"
    fi
    
    return $exit_code
}

# 发送通知（可选）
send_notification() {
    local message="$1"
    
    # 可以添加邮件/Telegram/钉钉等通知
    # 例如: curl -s -X POST "https://api.telegram.org/bot$TOKEN/sendMessage" -d "chat_id=$CHAT_ID" -d "text=$message"
    
    log "通知: $message"
}

# 自动提交推送（静默执行）
auto_commit_push() {
    # 检查是否是 git 仓库
    if [ ! -d "$PROJECT_ROOT/.git" ]; then
        return 0
    fi
    
    # 切换到项目目录执行 git 操作
    cd "$PROJECT_ROOT" || return 0
    
    # 检查是否有需要提交的更改
    if git diff --quiet && git diff --cached --quiet; then
        return 0
    fi
    
    # 添加更改（静默执行，不输出任何内容）
    git add -A 2>/dev/null
    
    # 提交（使用当前时间作为提交信息）
    local commit_msg="Update: $(date '+%Y-%m-%d %H:%M')"
    git commit -m "$commit_msg" 2>/dev/null
    
    # 推送到远程（静默执行）
    git push 2>/dev/null
}

# 生成 Hugo 博客文章（静默执行）
generate_blog_html() {
    local content_dir="$PROJECT_ROOT/content/posts"
    local summary_file="$DATA_DIR/summary_latest.md"
    local config_file="$PROJECT_ROOT/config/config.json"
    
    [ ! -f "$summary_file" ] && return 0
    
    mkdir -p "$content_dir"
    
    local date_str=$(date +%Y-%m-%d_%H-%M)
    local timestamp=$(date -Iseconds)
    local content=$(cat "$summary_file")
    local post_file="$content_dir/$date_str.md"
    
    # 从配置中读取任务名称
    local task_name="Monitor Report"
    if [ -f "$config_file" ]; then
        task_name=$(jq -r '.taskName // "Monitor Report"' "$config_file")
    fi
    
    cat > "$post_file" << EOF
---
title: "$date_str $task_name"
date: $timestamp
description: "$task_name"
categories: ["Report"]
tags: ["Automation", "AI"]
---

$content
EOF
}

# 主函数
main() {
    # 初始化日志目录
    mkdir -p "$LOG_DIR"
    
    log "========== 开始技术创新监测任务 =========="
    
    # 检查依赖
    check_dependencies
    
    # 检查 lock
    check_lock
    
    # 加载配置
    load_config
    
    # 执行任务
    execute_with_retry
    exit_code=$?
    
    log "========== 任务完成 =========="
    
    exit $exit_code
}

main "$@"
