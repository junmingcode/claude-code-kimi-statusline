#!/usr/bin/env bash
# ============================================
# Claude Code Kimi Statusline — 一键安装脚本
# ============================================

set -e

REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TARGET_DIR="$HOME/.claude"
STATUSLINE_FILE="$TARGET_DIR/statusline.sh"
SETTINGS_FILE="$TARGET_DIR/settings.json"

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${BLUE}========================================${NC}"
echo -e "${BLUE}  Claude Code Kimi Statusline 安装器${NC}"
echo -e "${BLUE}========================================${NC}"
echo ""

# 检查环境
if [ ! -d "$TARGET_DIR" ]; then
    echo -e "${YELLOW}[提示] 创建 Claude Code 配置目录: $TARGET_DIR${NC}"
    mkdir -p "$TARGET_DIR"
fi

# 复制状态栏脚本
echo -e "${BLUE}[1/3] 复制状态栏脚本...${NC}"
cp "$REPO_DIR/statusline.sh" "$STATUSLINE_FILE"
chmod +x "$STATUSLINE_FILE"
echo -e "${GREEN}  ✓ 已复制到 $STATUSLINE_FILE${NC}"

# 配置 settings.json
echo -e "${BLUE}[2/3] 配置 settings.json...${NC}"

# 使用 Python 处理 JSON（更可靠）
PYTHON_CMD=""
if command -v python3 >/dev/null 2>&1 && python3 -c "pass" 2>/dev/null; then
    PYTHON_CMD="python3"
elif command -v python >/dev/null 2>&1 && python -c "pass" 2>/dev/null; then
    PYTHON_CMD="python"
else
    echo -e "${RED}  ✗ 未找到可用的 Python 命令${NC}"
    echo -e "${YELLOW}  请手动编辑 $SETTINGS_FILE，添加以下内容：${NC}"
    cat << 'EOF'

{
  "statusLine": {
    "type": "command",
    "command": "bash ~/.claude/statusline.sh"
  }
}

EOF
    exit 1
fi

$PYTHON_CMD -c "
import json
import os

settings_path = os.path.expanduser('$SETTINGS_FILE')
data = {}

# 读取现有配置
if os.path.exists(settings_path):
    try:
        with open(settings_path, 'r', encoding='utf-8') as f:
            content = f.read().strip()
            if content:
                data = json.loads(content)
    except Exception as e:
        print(f'Warning: 读取现有 settings.json 失败: {e}')
        data = {}

# 确保 env 存在
if 'env' not in data or not isinstance(data['env'], dict):
    data['env'] = {}

# 设置 Kimi API 环境变量（如果未设置）
env_defaults = {
    'ANTHROPIC_BASE_URL': 'https://api.kimi.com/coding/',
    'ANTHROPIC_DEFAULT_SONNET_MODEL': 'kimi-for-coding',
    'ANTHROPIC_DEFAULT_OPUS_MODEL': 'kimi-for-coding',
    'ANTHROPIC_SMALL_FAST_MODEL': 'kimi-for-coding',
}
for key, val in env_defaults.items():
    if key not in data['env'] or not data['env'][key]:
        data['env'][key] = val

# 设置 statusLine
data['statusLine'] = {
    'type': 'command',
    'command': 'bash ~/.claude/statusline.sh'
}

# 写入文件
with open(settings_path, 'w', encoding='utf-8') as f:
    json.dump(data, f, ensure_ascii=False, indent=2)

print('settings.json 已更新')
" || {
    echo -e "${RED}  ✗ Python 处理 settings.json 失败${NC}"
    echo -e "${YELLOW}  请手动编辑 $SETTINGS_FILE，添加以下内容：${NC}"
    cat << 'EOF'

{
  "statusLine": {
    "type": "command",
    "command": "bash ~/.claude/statusline.sh"
  }
}

EOF
    exit 1
}

echo -e "${GREEN}  ✓ settings.json 已更新${NC}"

# 验证安装
echo -e "${BLUE}[3/3] 验证安装...${NC}"
if bash "$STATUSLINE_FILE" >/dev/null 2>&1; then
    echo -e "${GREEN}  ✓ 状态栏脚本运行正常${NC}"
else
    echo -e "${YELLOW}  ⚠ 脚本测试输出异常（可能是 API Key 未配置）${NC}"
fi

echo ""
echo -e "${GREEN}========================================${NC}"
echo -e "${GREEN}  🎉 安装完成！${NC}"
echo -e "${GREEN}========================================${NC}"
echo ""
echo "请确保你的 settings.json 中包含 Kimi API Key:"
echo ""
echo -e "  ${YELLOW}ANTHROPIC_AUTH_TOKEN${NC}: sk-kimi-xxxxxxxx"
echo ""
echo "配置方式：编辑 $SETTINGS_FILE"
echo ""
echo "安装完成后，重启 Claude Code 即可看到状态栏效果。"
echo ""
