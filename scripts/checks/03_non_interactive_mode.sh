#!/usr/bin/env bash
# Check 03: Non-Interactive Mode
# TTY なし・stdin クローズ状態でも正常完了すること。
# インタラクティブなプロンプトを表示しないこと。
set -uo pipefail

FAILURES=0
TIMEOUT_SECS=10
pass() { echo "  ✓ $1"; }
fail() { echo "  ✗ $1"; FAILURES=$((FAILURES + 1)); }
info() { echo "    → $1"; }

# 3a: TTY なし・stdin クローズで完了する
echo "Testing: runs without TTY (stdin redirected from /dev/null)"
output=$(timeout "${TIMEOUT_SECS}" ${CLI_CMD} ${RESOURCE} ${LIST_VERB} </dev/null 2>&1); code=$?

if [ "${code}" -eq 124 ]; then
    fail "CLI timed out (${TIMEOUT_SECS}s) — likely waiting for interactive input"
elif [ "${code}" -eq 0 ]; then
    pass "CLI completes successfully without TTY (exit 0)"
else
    fail "CLI failed when run without TTY (exit ${code})"
    info "Output: ${output}"
fi

# 3b: インタラクティブプロンプトが含まれない
echo "Testing: no interactive prompts in output"
PROMPT_PATTERNS=(
    "Enter "
    "Password:"
    "password:"
    "Username:"
    "username:"
    "(y/n)"
    "(Y/N)"
    "[y/n]"
    "[Y/N]"
)

found_prompt=0
for pattern in "${PROMPT_PATTERNS[@]}"; do
    if echo "${output}" | grep -qF "${pattern}"; then
        fail "Interactive prompt pattern detected: '${pattern}'"
        found_prompt=1
    fi
done

if [ "${found_prompt}" -eq 0 ]; then
    pass "No interactive prompt patterns found in output"
fi

[ "${FAILURES}" -eq 0 ]
