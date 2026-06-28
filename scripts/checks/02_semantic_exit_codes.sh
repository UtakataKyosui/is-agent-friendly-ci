#!/usr/bin/env bash
# Check 02: Semantic Exit Codes
# 終了コードの意味:
#   0 = 成功
#   1 = 一般エラー
#   2 = 引数/使い方エラー
#   3 = リソース未発見
#   4 = 認証エラー (省略可)
#   5 = バリデーションエラー (省略可)
set -uo pipefail

FAILURES=0
pass() { echo "  ✓ $1"; }
fail() { echo "  ✗ $1"; FAILURES=$((FAILURES + 1)); }
info() { echo "    → $1"; }

check_exit_code() {
    local desc="$1"
    local expected="$2"
    local actual="$3"
    if [ "${actual}" -eq "${expected}" ]; then
        pass "${desc} → exit ${actual}"
    else
        fail "${desc} → expected exit ${expected}, got ${actual}"
    fi
}

# 2a: 成功時は exit 0
echo "Testing success: ${CLI_CMD} ${RESOURCE} ${LIST_VERB}"
${CLI_CMD} ${RESOURCE} ${LIST_VERB} > /dev/null 2>&1; code=$?
check_exit_code "Success case exits with 0" 0 "${code}"

# 2b: 不正な引数は exit 2
echo "Testing argument error: ${CLI_CMD} ${INVALID_ARGS}"
${CLI_CMD} ${INVALID_ARGS} > /dev/null 2>&1; code=$?
check_exit_code "Invalid arguments exit with 2" 2 "${code}"

# 2c: 存在しないリソースは exit 3
echo "Testing not found: ${CLI_CMD} ${RESOURCE} ${GET_VERB} ${NONEXISTENT_ID}"
${CLI_CMD} ${RESOURCE} ${GET_VERB} ${NONEXISTENT_ID} > /dev/null 2>&1; code=$?
check_exit_code "Not found exits with 3" 3 "${code}"

[ "${FAILURES}" -eq 0 ]
