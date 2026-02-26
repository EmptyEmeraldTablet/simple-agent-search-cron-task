# Cron Search Task
简易AI AGENT定时任务/自动化实验项目。

[English Version](./README_EN.md)

---

## 项目简介

本项目是一个长期进行的实验项目，旨在探索如何利用 AI Agent 实现定时技术创新内容监测的自动化。

### 核心功能

- **定时搜索**：通过 cron + opencode run 实现定时任务
- **多源监测**：覆盖 GitHub、arXiv、Reddit、Hacker News 等技术信息来源
- **智能去重**：基于内容指纹的去重机制，避免重复收录
- **结果分析**：自动生成结构化分析报告
- **博客发布**：自动将监测报告发布为静态博客

### 技术栈

- **opencode**：AI 编程 Agent
- **cron**：Linux 定时任务
- **bash**：任务脚本
- **Hugo**：静态博客生成器
- **Cloudflare Pages**：静态网站托管

### 项目能做什么

1. **定时追踪技术动态**：每天自动搜索你关注的技术关键词
2. **去重过滤**：自动过滤已收录的内容，只展示真正的新内容
3. **结构化报告**：生成易于阅读的监测摘要
4. **自动发布**：将报告自动构建为静态博客并部署

## 部署示例

本项目的博客部署示例：

**👉 [https://simple-agent-search-cron-task.pages.dev/](https://simple-agent-search-cron-task.pages.dev/)**

可以在此链接查看当前任务的执行结果。

---

## 快速开始

### 1. 安装依赖

```bash
# 安装 opencode
curl -fsSL https://opencode.ai/install | bash

# 安装 jq
apt install jq
```

### 2. 配置关键词

编辑 `config/config.json` 中的 `searchKeywords` 数组：

```json
{
  "searchKeywords": [
    "AI agent automation best practices 2026",
    "GitHub trending open source tools"
  ]
}
```

### 3. 测试运行

```bash
cd scripts
MOCK_MODE=true ./cron-search.sh  # 模拟模式测试
./cron-search.sh                  # 真实运行
```

### 4. 设置定时任务

```bash
./cron-search-setup.sh
```

选择执行频率后自动配置 cron。

### 5. 部署博客（可选）

#### 方式一：Cloudflare Pages（推荐）

1. 登录 [Cloudflare Dashboard](https://dash.cloudflare.com/)
2. 进入 **Pages** → **Connect to Git**
3. 选择本仓库
4. 配置：
   - **构建命令**：`hugo --gc --minify`
   - **输出目录**：`public`
5. 点击 **保存并部署**

#### 方式二：Vercel

1. 登录 [Vercel](https://vercel.com/)
2. Import Git Repository
3. 配置：
   - **Framework Preset**：Hugo
   - **Build Command**：`hugo --gc --minify`
   - **Output Directory**：`public`
4. 点击 **Deploy**

---

## 文件结构

```
cron-search-test/
├── config/
│   └── config.json              # 搜索关键词配置
├── data/
│   ├── content_registry.json    # 内容注册表（去重）
│   └── summary_latest.md       # 最新摘要+指纹
├── content/
│   └── posts/                  # Hugo 文章目录（自动生成）
├── layouts/                     # Hugo 模板
├── logs/
│   ├── summary.log             # 执行日志
│   └── error.log               # 错误日志
├── scripts/
│   ├── cron-search.sh          # 主任务脚本
│   ├── mock-opencode-run.sh    # 模拟测试脚本
│   ├── diagnose.sh             # 诊断工具
│   └── cron-search-setup.sh    # cron 设置脚本
├── hugo.toml                   # Hugo 配置
├── opencode.json               # opencode 权限配置
└── README.md
```

---

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

---

## 配置说明

### 关键词配置

在 `config/config.json` 中修改搜索关键词。建议使用英文关键词以获得更好的搜索结果：

```json
{
  "searchKeywords": [
    "cron job scheduling best practices 2026",
    "AI agent automation task scheduling",
    "GitHub trending open source automation tools",
    "LLM autonomous agent framework",
    "Hacker News programming discussion 2026"
  ]
}
```

### 权限配置

`opencode.json` 中配置了文件操作权限，确保任务可以后台自动执行：

```json
{
  "permission": {
    "*": "allow",
    "external_directory": {
      "**": "allow"
    }
  }
}
```

---

## 注意事项

- 本项目为实验性质，不保证长期维护
- 搜索结果质量依赖 opencode 模型表现
- 需要配置 API Key 才能使用 opencode
- 博客部署需要根据实际情况调整 Hugo 模板样式

---

## License

MIT
