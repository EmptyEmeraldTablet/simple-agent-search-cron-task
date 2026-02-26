# Cron Search Task

定时技术创新监测任务自动化实验项目。

## 项目简介

本项目是一个长期进行的实验项目，旨在探索如何利用 AI Agent 实现定时技术创新内容监测的自动化。

### 核心功能

- **定时搜索**：通过 cron + opencode run 实现定时任务
- **多源监测**：覆盖 GitHub、arXiv、Reddit、Hacker News 等技术信息来源
- **智能去重**：基于内容指纹的去重机制，避免重复收录
- **结果分析**：自动生成结构化分析报告

### 技术栈

- **opencode**：AI 编程 Agent
- **cron**：Linux 定时任务
- **bash**：任务脚本

## 文件结构

```
cron-search-test/
├── config/
│   └── config.json              # 搜索关键词配置
├── data/
│   ├── content_registry.json   # 内容注册表（去重）
│   └── summary_latest.md       # 最新摘要+指纹
├── logs/
│   ├── summary.log              # 执行日志
│   └── error.log               # 错误日志
├── scripts/
│   ├── cron-search.sh          # 主任务脚本
│   ├── mock-opencode-run.sh    # 模拟测试脚本
│   ├── diagnose.sh             # 诊断工具
│   └── cron-search-setup.sh   # cron 设置脚本
├── opencode.json               # opencode 权限配置
└── README.md
```

## 快速开始

### 1. 安装依赖

```bash
# 安装 opencode
curl -fsSL https://opencode.ai/install | bash

# 安装 jq
apt install jq
```

### 2. 配置关键词

编辑 `config/config.json` 中的 `searchKeywords` 数组。

### 3. 测试运行

```bash
cd scripts
MOCK_MODE=true ./cron-search.sh  # 模拟模式测试
./cron-search.sh                # 真实运行
```

### 4. 设置定时任务

```bash
./cron-search-setup.sh
```

选择执行频率后自动配置 cron。

## 使用说明

### 手动执行

```bash
./scripts/cron-search.sh
```

### 查看日志

```bash
# 详细日志
tail -f logs/summary.log

# 错误日志
cat logs/error.log
```

### 诊断工具

```bash
./scripts/diagnose.sh
```

## 配置说明

### 关键词配置

在 `config/config.json` 中修改：

```json
{
  "searchKeywords": [
    "your keyword 1",
    "your keyword 2"
  ]
}
```

### 权限配置

`opencode.json` 中配置了文件操作权限，确保任务可以后台自动执行。

## 注意事项

- 本项目为实验性质，不保证长期维护
- 搜索结果质量依赖 opencode 模型表现
- 需要配置 API Key 才能使用 opencode

## License

MIT
