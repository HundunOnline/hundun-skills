#!/usr/bin/env bash
# AIA 对话记录写入 - POST /aia/api/v1/conversation/records（需鉴权）
# 用法: conversation_record.sh <source> <question> [answer]
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/_common.sh"

source_value="$1"
question="$2"
answer="${3:-已记录本次混沌 Skill 测试环境对话。}"
if [[ -z "$source_value" || -z "$question" ]]; then
    echo "用法: $0 <source> <question> [answer]" >&2
    exit 1
fi

load_config || exit 1
ts=$(date +%s)
source_id=$(printf '%s' "$source_value" | tr -cd 'A-Za-z0-9_.:-')
source_id="${source_id:-source}"
request_id="hundun-skill-conversation-${source_id}-${ts}"
session_id="hundun-skill-session-${source_id}-${ts}"

if command -v jq &>/dev/null; then
    body=$(jq -n \
        --arg client_id "hundun-skill" \
        --arg request_id "$request_id" \
        --arg session_id "$session_id" \
        --arg scene_value "$source_value" \
        --arg user_input "$question" \
        --arg ai_final_answer "$answer" \
        --arg client_version "$HUNDUN_SKILL_VERSION" \
        --argjson timestamp "$ts" \
        '{client_id:$client_id,request_id:$request_id,session_id:$session_id,scene_value:$scene_value,user_input:$user_input,ai_final_answer:$ai_final_answer,client_version:$client_version,timestamp:$timestamp}')
elif command -v python3 &>/dev/null || command -v python &>/dev/null; then
    py=$(command -v python3 2>/dev/null || command -v python 2>/dev/null)
    body=$("$py" -c 'import json,sys; print(json.dumps({"client_id":"hundun-skill","request_id":sys.argv[1],"session_id":sys.argv[2],"scene_value":sys.argv[3],"user_input":sys.argv[4],"ai_final_answer":sys.argv[5],"client_version":sys.argv[6],"timestamp":int(sys.argv[7])}, ensure_ascii=False))' "$request_id" "$session_id" "$source_value" "$question" "$answer" "$HUNDUN_SKILL_VERSION" "$ts")
else
    echo "错误：需要 jq 或 python/python3 生成 JSON，请安装其一" >&2
    exit 1
fi

raw=$(api_post "/aia/api/v1/conversation/records" "$body")
parse_response "$raw"
