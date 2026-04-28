#!/usr/bin/env bash
# ============================================
# Claude Code Kimi Statusline — 卸载脚本
# ============================================

set -e

TARGET_DIR="$HOME/.claude"
STATUSLINE_FILE="$TARGET_DIR/statusline.sh"
SETTINGS_FILE="$TARGET_DIR/settings.json"

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

echo -e "${BLUE}========================================${NC}"
echo -e "${BLUE}  Claude Code Kimi Statusline 卸载器${NC}"
echo -e "${BLUE}========================================${NC}"
echo ""

# 删除状态栏脚本
if [ -f "$STATUSLINE_FILE" ]; then
    echo -e "${BLUE}[1/2] 删除状态栏脚本...${NC}"
    rm -f "$STATUSLINE_FILE"
    echo -e "${GREEN}  ✓ 已删除 $STATUSLINE_FILE${NC}"
else
    echo -e "${YELLOW}  ⚠ 状态栏脚本不存在，跳过${NC}"
fi

# 从 settings.json 中移除 statusLine
echo -e "${BLUE}[2/2] 清理 settings.json...${NC}"
if [ -f "$SETTINGS_FILE" ]; then
    if command -v python3 >/dev/null 2>&1; then
        python3 -c "
import json
import os

settings_path = os.path.expanduser('$SETTINGS_FILE')
if os.path.exists(settings_path):
    with open(settings_path, 'r', encoding='utf-8') as f:
        data = json.load(f)

    # 移除 statusLine
    if 'statusLine' in data:
        del data['statusLine']
        with open(settings_path, 'w', encoding='utf-8') as f:
            json.dump(data, f, ensure_ascii=False, indent=2)
        print('已从 settings.json 移除 statusLine 配置')
    else:
        print('settings.json 中没有 statusLine 配置')
else:
    print('settings.json 不存在')
"
    else
        echo -e "${YELLOW}  ⚠ 未找到 python3，请手动从 $SETTINGS_FILE 中删除 statusLine 字段${NC}"
    fi
else
    echo -e "${YELLOW}  ⚠ settings.json 不存在，跳过${NC}"
fi

echo ""
echo -e "${GREEN}========================================${NC}"
echo -e "${GREEN}  ✓ 卸载完成${NC}"
echo -e "${GREEN}========================================${NC}"
echo ""
echo "重启 Claude Code 后状态栏将恢复默认。"
echo ""
