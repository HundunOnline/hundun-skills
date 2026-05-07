#!/usr/bin/env bash
# AIA preflight check. The version endpoint itself does not require a key;
# this script keeps a local key-presence check so users get login guidance early.
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/_common.sh"

print_login_guidance() {
    echo "当前凭证可能已失效、无权限或未完成登录。请打开 https://tools.hundun.cn/h5Bin/aia/#/keys 登录混沌会员账号后，重新生成一个 hd_sk_ 开头的密钥发给 AI。拿到有效密钥后，我会继续当前任务。" >&2
}

load_config || exit 1

if [[ -z "$api_key" ]]; then
    print_login_guidance
    exit 1
fi

raw=$(api_get_no_auth "/aia/api/v1/version?client_version=$(urlencode "$HUNDUN_SKILL_VERSION")")
output=$(parse_response "$raw" 2>&1)
status=$?

if [[ $status -eq 0 ]]; then
    printf '%s\n' "$output"
    exit 0
fi

if printf '%s' "$output" | grep -Eqi 'api[_ -]?key|密钥|鉴权|权限|401|403|unauthorized|forbidden|失效|未登录'; then
    print_login_guidance
    exit 1
fi

printf '%s\n' "$output" >&2
exit 1
