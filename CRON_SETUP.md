# 定时任务设置指南

## 文件结构

```
cron-search-test/
├── config/
│   └── config.json          # 任务配置
├── data/
│   ├── content_registry.json   # 内容注册表（去重）
│   └── summary_latest.md       # 最新摘要+指纹
├── logs/
│   ├── summary.log          # 详细日志
│   ├── error.log           # 错误日志
│   └── running.lock        # 运行锁文件
└── scripts/
    ├── cron-search.sh      # 主任务脚本
    └── diagnose.sh         # 诊断工具
```

## 1. 添加 cron 任务

### 方式一：直接编辑 crontab

```bash
crontab -e
```

添加以下行：

```cron
# 每天早上 8 点执行
0 8 * * * /home/oyzy/cron/cron-search-test/scripts/cron-search.sh >> /home/oyzy/cron/cron-search-test/logs/cron-cron-search.log 2>&1

# 每小时执行（测试用）
0 * * * * /home/oyzy/cron/cron-search-test/scripts/cron-search.sh >> /home/oyzy/cron/cron-search-test/logs/cron-cron-search.log 2>&1
```

### 方式二：使用 cron-search-setup.sh（推荐）

```bash
cd /home/oyzy/cron/cron-search-test/scripts
chmod +x cron-search-setup.sh
./cron-search-setup.sh
```

按照提示选择执行时间和频率。

## 2. Cron 表达式说明

| 表达式 | 含义 |
|--------|------|
| `0 8 * * *` | 每天早上 8:00 |
| `0 8 * * 1-5` | 工作日早上 8:00 |
| `0 8,20 * * *` | 每天 8:00 和 20:00 |
| `0 */2 * * *` | 每 2 小时 |
| `0 0 * * 0` | 每周日午夜 |

## 3. 常用命令

```bash
# 查看 cron 任务
crontab -l

# 删除所有 cron 任务
crontab -r

# 查看任务日志
tail -f /home/oyzy/cron/cron-search-test/logs/cron-cron-search.log

# 查看错误日志
cat /home/oyzy/cron/cron-search-test/logs/error.log

# 手动执行任务
/home/oyzy/cron/cron-search-test/scripts/cron-search.sh

# 运行诊断工具
/home/oyzy/cron/cron-search-test/scripts/diagnose.sh
```

## 4. 故障排查

### 问题：任务不执行

1. 检查 cron 服务是否运行：
   ```bash
   systemctl status cron
   # 或
   service cron status
   ```

2. 检查脚本是否有执行权限：
   ```bash
   chmod +x /home/oyzy/cron/cron-search-test/scripts/cron-search.sh
   ```

3. 检查日志输出

### 问题：opencode 命令找不到

在脚本开头添加 PATH：
```bash
export PATH="$HOME/.local/bin:$PATH"
# 或
source ~/.bashrc
```

### 问题：任务执行但无输出

1. 检查 opencode 是否正确安装
2. 运行诊断工具：
   ```bash
   ./diagnose.sh
   ```

## 5. 通知配置（可选）

如需邮件/Telegram 通知，编辑 `cron-search.sh` 中的 `send_notification` 函数。

### Telegram 通知示例

```bash
send_notification() {
    local message="$1"
    local token="YOUR_BOT_TOKEN"
    local chat_id="YOUR_CHAT_ID"
    
    curl -s -X POST "https://api.telegram.org/bot$token/sendMessage" \
        -d "chat_id=$chat_id" \
        -d "text=[定时任务] $message"
}
```

## 6. 测试建议

在正式部署前，建议：

1. **手动测试**：运行 `./cron-search.sh` 确认脚本正常工作
2. **频繁测试**：先设置每分钟执行，观察日志
3. **检查输出**：确认搜索结果正确写入文件
4. **调整频率**：确认无误后改为每日执行

```bash
# 每分钟测试（调试用）
*/1 * * * * /home/oyzy/cron/cron-search-test/scripts/cron-search.sh >> /home/oyzy/cron/cron-search-test/logs/cron-cron-search.log 2>&1
```
