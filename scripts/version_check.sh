#!/usr/bin/env bash
# 版本检查 - GET /aia/api/v1/version（无需鉴权）
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/_common.sh"

base_url="${HDXY_API_BASE_URL:-$DEFAULT_BASE_URL}"
base_url="${base_url%/}"

raw=$(api_get_no_auth "/aia/api/v1/version")
parse_response "$raw"
