# Cron Search Task

Automated Scheduled Technology Innovation Monitoring Experiment.

[中文版本](./README.md)

---

## Project Overview

This is a long-running experiment project that explores how to use AI Agents for automated scheduled technology innovation content monitoring.

### Core Features

- **Scheduled Search**: Timed tasks via cron + opencode run
- **Multi-source Monitoring**: Covers GitHub, arXiv, Reddit, Hacker News, etc.
- **Smart Deduplication**: Content fingerprint-based deduplication to avoid duplicates
- **Result Analysis**: Auto-generates structured analysis reports
- **Blog Publishing**: Automatically publishes reports as static blogs

### Tech Stack

- **opencode**: AI Programming Agent
- **cron**: Linux scheduled tasks
- **bash**: Task scripts
- **Hugo**: Static blog generator
- **Cloudflare Pages**: Static site hosting

### What This Project Does

1. **Scheduled Technology Tracking**: Automatically search your interested tech keywords daily
2. **Deduplication Filter**: Automatically filter already recorded content, showing only new content
3. **Structured Reports**: Generate easy-to-read monitoring summaries
4. **Auto Publishing**: Automatically build and deploy reports as static blogs

## Demo

Blog deployment example:

**👉 [https://simple-agent-search-cron-task.pages.dev/](https://simple-agent-search-cron-task.pages.dev/)**

View current task execution results at this link.

---

## Quick Start

### 1. Install Dependencies

```bash
# Install opencode
curl -fsSL https://opencode.ai/install | bash

# Install jq
apt install jq
```

### 2. Configure Keywords

Edit `searchKeywords` array in `config/config.json`:

```json
{
  "searchKeywords": [
    "AI agent automation best practices 2026",
    "GitHub trending open source tools"
  ]
}
```

### 3. Test Run

```bash
cd scripts
MOCK_MODE=true ./cron-search.sh  # Mock mode for testing
./cron-search.sh                  # Real run
```

### 4. Set Up Cron Job

```bash
./cron-search-setup.sh
```

Select execution frequency to auto-configure cron.

### 5. Deploy Blog (Optional)

#### Option 1: Cloudflare Pages (Recommended)

1. Login to [Cloudflare Dashboard](https://dash.cloudflare.com/)
2. Go to **Pages** → **Connect to Git**
3. Select this repository
4. Configure:
   - **Build command**: `hugo --gc --minify`
   - **Output directory**: `public`
5. Click **Save and Deploy**

#### Option 2: Vercel

1. Login to [Vercel](https://vercel.com/)
2. Import Git Repository
3. Configure:
   - **Framework Preset**: Hugo
   - **Build Command**: `hugo --gc --minify`
   - **Output Directory**: `public`
4. Click **Deploy**

---

## File Structure

```
cron-search-test/
├── config/
│   └── config.json              # Search keywords configuration
├── data/
│   ├── content_registry.json    # Content registry (deduplication)
│   └── summary_latest.md       # Latest summary + fingerprint
├── content/
│   └── posts/                  # Hugo posts directory (auto-generated)
├── layouts/                     # Hugo templates
├── logs/
│   ├── summary.log             # Execution log
│   └── error.log               # Error log
├── scripts/
│   ├── cron-search.sh          # Main task script
│   ├── mock-opencode-run.sh    # Mock test script
│   ├── diagnose.sh             # Diagnostic tool
│   └── cron-search-setup.sh    # Cron setup script
├── hugo.toml                   # Hugo configuration
├── opencode.json               # Opencode permission config
└── README.md
```

---

## Usage

### Manual Execution

```bash
./scripts/cron-search.sh
```

### View Logs

```bash
# Detailed log
tail -f logs/summary.log

# Error log
cat logs/error.log
```

### Diagnostic Tool

```bash
./scripts/diagnose.sh
```

---

## Configuration

### Keywords Configuration

Modify search keywords in `config/config.json`. English keywords are recommended for better search results:

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

### Permission Configuration

`opencode.json` configures file operation permissions to allow background execution:

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

## Notes

- This is an experimental project, no long-term maintenance guaranteed
- Search result quality depends on opencode model performance
- API Key configuration is required to use opencode
- Blog deployment requires Hugo template style adjustments based on actual needs

---

## License

MIT
