# Claude Code Kimi Statusline 🎨

为 [Claude Code](https://claude.ai/code) 打造的炫酷实时状态栏，集成 **Kimi API** 用量监控，让你时刻掌握模型使用状态。

---

## ✨ 功能特性

| 显示项 | 说明 |
|--------|------|
| 🤖 **当前模型** | 显示完整的模型名称（如 `kimi-for-coding`） |
| 📁 **当前目录** | 路径过长时自动精简显示 |
| 󰊢 **Git 分支** | 显示当前分支名及 dirty 状态（`*`） |
| **5h 用量** | Kimi 5小时窗口用量百分比 + 彩色进度条 |
| **7d 用量** | Kimi 7天窗口用量百分比 + 彩色进度条 |
| ⏱ **实时时间** | 当前时间 HH:MM:SS |
| 🔥 **项目标识** | 在特定项目目录下显示项目名（可自定义） |

### 颜色阈值

| 用量范围 | 颜色 | 含义 |
|----------|------|------|
| 0% - 60% | 🟢 绿色 | 用量充足 |
| 60% - 85% | 🟡 黄色 | 注意用量 |
| 85% - 100% | 🔴 红色 | 用量紧张 |

---

## 📸 效果预览

```
🤖 kimi-for-coding │ 📁 .../code/tomato │ 5h:20%=--- │ 7d:27%==== │ ⏱ 11:46:49 │ 🔥 gitee-scan
```

---

## 🚀 快速安装

### 方式一：一键安装（推荐）

```bash
git clone https://github.com/junmingcode/claude-code-kimi-statusline.git
cd claude-code-kimi-statusline
bash install.sh
```

### 方式二：手动安装

1. 复制 `statusline.sh` 到 `~/.claude/statusline.sh`
2. 编辑 `~/.claude/settings.json`，添加：

```json
{
  "statusLine": {
    "type": "command",
    "command": "bash ~/.claude/statusline.sh"
  }
}
```

### 配置 API Key

确保你的 `~/.claude/settings.json` 中包含 Kimi API Key：

```json
{
  "env": {
    "ANTHROPIC_AUTH_TOKEN": "sk-kimi-xxxxxxxx",
    "ANTHROPIC_BASE_URL": "https://api.kimi.com/coding/",
    "ANTHROPIC_DEFAULT_SONNET_MODEL": "kimi-for-coding"
  },
  "statusLine": {
    "type": "command",
    "command": "bash ~/.claude/statusline.sh"
  }
}
```

### 重启 Claude Code

安装完成后，**重启 Claude Code** 即可看到状态栏效果。

---

## 🔧 自定义配置

### 修改项目标识

编辑 `~/.claude/statusline.sh`，找到以下代码修改或添加项目标识：

```bash
# 项目标识（可自定义）
if [[ "$pwd_short" == *"your-project"* ]] || [[ "$PWD" == *"your-project"* ]]; then
    output+=" ${DIM}│${RESET} "
    output+="${BRIGHT_RED}${ICON_FIRE} your-project${RESET}"
fi
```

### 调整缓存时间

编辑脚本顶部的 `CACHE_TTL`：

```bash
CACHE_TTL=30  # 单位：秒，默认 30 秒
```

---

## 🗑️ 卸载

```bash
bash uninstall.sh
```

或手动删除 `~/.claude/statusline.sh` 并从 `settings.json` 中移除 `statusLine` 字段。

---

## 📋 系统要求

- **Bash**（Windows 需 Git Bash / MSYS2 / WSL）
- **Python 3** 或 **curl**（用于调用 Kimi API）
- **Claude Code** CLI 工具

---

## 🤝 贡献

欢迎提交 Issue 和 PR！

---

## 📄 License

[MIT](LICENSE)
