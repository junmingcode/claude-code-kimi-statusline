#!/usr/bin/env bash
# ============================================
# Claude Code Kimi Statusline
# 炫酷状态栏 — 直接查询 Kimi API 用量
# ============================================
# 仓库: https://github.com/junmingcode/claude-code-kimi-statusline
# License: MIT
# ============================================

set -e

# 颜色定义
RESET="\033[0m"
BOLD="\033[1m"
DIM="\033[2m"

RED="\033[31m"
GREEN="\033[32m"
YELLOW="\033[33m"
BLUE="\033[34m"
MAGENTA="\033[35m"
CYAN="\033[36m"

BRIGHT_RED="\033[91m"
BRIGHT_GREEN="\033[92m"
BRIGHT_YELLOW="\033[93m"
BRIGHT_BLUE="\033[94m"
BRIGHT_MAGENTA="\033[95m"
BRIGHT_CYAN="\033[96m"

BG_BLUE="\033[44m"
BG_BLACK="\033[40m"

ICON_MODEL="🤖"
ICON_FOLDER="📁"
ICON_GIT="🌿"
ICON_TIME="⏱"
ICON_FIRE="🔥"

# API 配置
API_KEY="${ANTHROPIC_AUTH_TOKEN:-}"
USAGE_API="https://api.kimi.com/coding/v1/usages"
CACHE_FILE="$HOME/.claude/token_usage_cache.json"
CACHE_TTL=30  # 缓存30秒，避免频繁请求

# 获取模型名称
get_model_name() {
    echo "${ANTHROPIC_DEFAULT_SONNET_MODEL:-kimi-for-coding}"
}

# 获取 Git 信息
get_git_info() {
    if ! git rev-parse --git-dir > /dev/null 2>&1; then
        echo ""
        return
    fi
    local branch=$(git symbolic-ref --short HEAD 2>/dev/null || git rev-parse --short HEAD 2>/dev/null)
    local dirty=""
    if ! git diff --quiet 2>/dev/null || ! git diff --cached --quiet 2>/dev/null; then
        dirty="*"
    fi
    echo "${branch}${dirty}"
}

# 获取当前目录（精简显示）
get_pwd() {
    local pwd=$(pwd)
    local home="$HOME"
    if [[ "$pwd" == "$home"* ]]; then
        pwd="~${pwd#$home}"
    fi
    local parts=$(echo "$pwd" | tr '/' '\n')
    local count=$(echo "$parts" | wc -l)
    if [ "$count" -gt 3 ]; then
        echo ".../$(echo "$pwd" | awk -F'/' '{print $(NF-1)"/"$NF}')"
    else
        echo "$pwd"
    fi
}

# 缩写大数字
fmt_short() {
    local n=$1
    if [ "$n" -ge 1000000 ]; then
        echo "$((n / 1000000)).$(((n % 1000000) / 100000))M"
    elif [ "$n" -ge 1000 ]; then
        echo "$((n / 1000)).$(((n % 1000) / 100))K"
    else
        echo "$n"
    fi
}

# 绘制进度条
draw_bar() {
    local pct=$1
    local width=${2:-4}
    if [ "$pct" -gt 100 ]; then pct=100; fi
    local filled=$((width * pct / 100))
    if [ "$filled" -gt "$width" ]; then filled=$width; fi
    local empty=$((width - filled))
    printf '%*s' "$filled" '' | tr ' ' '='
    printf '%*s' "$empty" '' | tr ' ' '-'
}

# 从缓存读取数据
read_cache() {
    if [ ! -f "$CACHE_FILE" ]; then
        echo ""
        return
    fi
    # 检查缓存是否过期
    local now=$(date +%s)
    local mtime=$(stat -c %Y "$CACHE_FILE" 2>/dev/null || stat -f %m "$CACHE_FILE" 2>/dev/null || echo 0)
    if [ $((now - mtime)) -gt $CACHE_TTL ]; then
        echo ""
        return
    fi
    cat "$CACHE_FILE"
}

# 写入缓存
write_cache() {
    echo "$1" > "$CACHE_FILE"
}

# 查询 Kimi API 获取用量
fetch_kimi_usage() {
    if [ -z "$API_KEY" ]; then
        echo "0|0|0|0|0|0|no_key"
        return
    fi

    # 先检查缓存
    local cached=$(read_cache)
    if [ -n "$cached" ]; then
        echo "$cached"
        return
    fi

    # 调用 API（带超时）
    local resp=""
    local http_code=""
    if command -v curl >/dev/null 2>&1; then
        resp=$(curl -s -m 3 -H "Authorization: Bearer $API_KEY" -H "Content-Type: application/json" "$USAGE_API" 2>/dev/null || echo "{}")
    elif command -v python3 >/dev/null 2>&1; then
        resp=$(python3 -c "
import urllib.request, json, sys
try:
    req = urllib.request.Request('$USAGE_API', headers={'Authorization': 'Bearer $API_KEY', 'Content-Type': 'application/json'})
    with urllib.request.urlopen(req, timeout=3) as resp:
        print(resp.read().decode('utf-8'))
except Exception as e:
    print('{}')
" 2>/dev/null)
    else
        echo "0|0|0|0|0|0|no_tool"
        return
    fi

    # 解析 JSON
    local result=""
    if command -v python3 >/dev/null 2>&1; then
        result=$(python3 -c "
import json, sys
try:
    d = json.loads(sys.stdin.read())
    pct_5h = 0
    pct_7d = 0
    used_5h = 0
    limit_5h = 0
    used_7d = 0
    limit_7d = 0

    usage = d.get('usage', {})
    if usage:
        limit = int(usage.get('limit', 0))
        used = int(usage.get('used', 0))
        used_7d = used
        limit_7d = limit
        if limit > 0:
            pct_7d = min(100, int(used * 100 / limit))

    limits = d.get('limits', [])
    for item in limits:
        window = item.get('window', {})
        detail = item.get('detail', {})
        if window.get('duration') == 300 and window.get('timeUnit') == 'TIME_UNIT_MINUTE':
            limit = int(detail.get('limit', 0))
            used = int(detail.get('used', 0))
            used_5h = used
            limit_5h = limit
            if limit > 0:
                pct_5h = min(100, int(used * 100 / limit))

    print(f'{pct_5h}|{pct_7d}|{used_5h}|{limit_5h}|{used_7d}|{limit_7d}|ok')
except Exception as e:
    print(f'0|0|0|0|0|0|error:{e}')
" <<< "$resp" 2>/dev/null)
    elif command -v jq >/dev/null 2>&1; then
        local pct_5h=0 pct_7d=0
        local used_5h=0 limit_5h=0 used_7d=0 limit_7d=0
        local usage_limit=$(echo "$resp" | jq -r '.usage.limit // 0')
        local usage_used=$(echo "$resp" | jq -r '.usage.used // 0')
        if [ "$usage_limit" -gt 0 ]; then
            pct_7d=$((usage_used * 100 / usage_limit))
            used_7d=$usage_used
            limit_7d=$usage_limit
        fi
        local limit_detail=$(echo "$resp" | jq -r '.limits[0].detail // {}')
        local lh_limit=$(echo "$limit_detail" | jq -r '.limit // 0')
        local lh_used=$(echo "$limit_detail" | jq -r '.used // 0')
        if [ "$lh_limit" -gt 0 ]; then
            pct_5h=$((lh_used * 100 / lh_limit))
            used_5h=$lh_used
            limit_5h=$lh_limit
        fi
        result="${pct_5h}|${pct_7d}|${used_5h}|${limit_5h}|${used_7d}|${limit_7d}|ok"
    else
        echo "0|0|0|0|0|0|no_parser"
        return
    fi

    # 写入缓存
    write_cache "$result"
    echo "$result"
}

# 获取时间
get_time() {
    date +"%H:%M:%S"
}

# 主输出函数
main() {
    local model=$(get_model_name)
    local git_info=$(get_git_info)
    local pwd_short=$(get_pwd)
    local time_str=$(get_time)
    local usage_str=$(fetch_kimi_usage)

    local pct_5h=$(echo "$usage_str" | cut -d'|' -f1)
    local pct_7d=$(echo "$usage_str" | cut -d'|' -f2)
    local used_5h=$(echo "$usage_str" | cut -d'|' -f3)
    local limit_5h=$(echo "$usage_str" | cut -d'|' -f4)
    local used_7d=$(echo "$usage_str" | cut -d'|' -f5)
    local limit_7d=$(echo "$usage_str" | cut -d'|' -f6)
    local status=$(echo "$usage_str" | cut -d'|' -f7)

    local output=""

    # 模型信息
    output+="${BG_BLUE}${BOLD} ${ICON_MODEL} ${model} ${RESET}"
    output+=" ${DIM}│${RESET} "

    # 当前目录
    output+="${CYAN}${ICON_FOLDER} ${pwd_short}${RESET}"

    # Git 信息
    if [ -n "$git_info" ]; then
        output+=" ${DIM}│${RESET} "
        output+="${MAGENTA}${ICON_GIT} ${git_info}${RESET}"
    fi

    output+=" ${DIM}│${RESET} "

    # 用量百分比
    local color_5h="$BRIGHT_GREEN"
    if [ "$pct_5h" -gt 85 ]; then color_5h="$BRIGHT_RED"
    elif [ "$pct_5h" -gt 60 ]; then color_5h="$BRIGHT_YELLOW"
    fi

    local color_7d="$BRIGHT_GREEN"
    if [ "$pct_7d" -gt 85 ]; then color_7d="$BRIGHT_RED"
    elif [ "$pct_7d" -gt 60 ]; then color_7d="$BRIGHT_YELLOW"
    fi

    if [ "$status" = "ok" ]; then
        output+="${color_5h}5h:${pct_5h}%$(draw_bar "$pct_5h" 4)${RESET}"
        output+=" ${DIM}│${RESET} "
        output+="${color_7d}7d:${pct_7d}%$(draw_bar "$pct_7d" 4)${RESET}"
    elif [ "$status" = "no_key" ]; then
        output+="${DIM}5h:? 7d:? (no key)${RESET}"
    else
        output+="${DIM}5h:${pct_5h}% 7d:${pct_7d}%${RESET}"
    fi

    output+=" ${DIM}│${RESET} "

    # 时间
    output+="${DIM}${ICON_TIME} ${time_str}${RESET}"

    # 项目标识（可自定义）
    if [[ "$pwd_short" == *"tomato"* ]] || [[ "$PWD" == *"gitee-scan"* ]]; then
        output+=" ${DIM}│${RESET} "
        output+="${BRIGHT_RED}${ICON_FIRE} gitee-scan${RESET}"
    fi

    echo -e "$output"
}

main
