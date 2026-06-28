#!/usr/bin/env bash
# Check 01: Structured Output
# stdout は JSON で、schema_version と kind フィールドを含むこと。
# エラーメッセージは stderr に出力されること。
set -uo pipefail

FAILURES=0
pass() { echo "  ✓ $1"; }
fail() { echo "  ✗ $1"; FAILURES=$((FAILURES + 1)); }
info() { echo "    → $1"; }

echo "Command: ${CLI_CMD} ${RESOURCE} ${LIST_VERB}"

# 1a: stdout が valid JSON
stdout_output=$(${CLI_CMD} ${RESOURCE} ${LIST_VERB} 2>/dev/null)
if echo "${stdout_output}" | jq . > /dev/null 2>&1; then
    pass "stdout is valid JSON"
else
    fail "stdout is not valid JSON"
    info "Got: ${stdout_output}"
fi

# 1b: schema_version フィールドの存在
if echo "${stdout_output}" | jq -e '.schema_version' > /dev/null 2>&1; then
    ver=$(echo "${stdout_output}" | jq -r '.schema_version')
    pass "JSON has 'schema_version' field (value: ${ver})"
else
    fail "JSON missing 'schema_version' field"
fi

# 1c: kind フィールドの存在
if echo "${stdout_output}" | jq -e '.kind' > /dev/null 2>&1; then
    kind=$(echo "${stdout_output}" | jq -r '.kind')
    pass "JSON has 'kind' field (value: ${kind})"
else
    fail "JSON missing 'kind' field"
fi

# 1d: エラー時に stdout を汚染しない
invalid_stdout=$(${CLI_CMD} ${INVALID_ARGS} 2>/dev/null || true)
if [ -z "${invalid_stdout}" ]; then
    pass "Error output does not appear on stdout (stdout is empty on error)"
elif echo "${invalid_stdout}" | jq -e '.error // .kind' > /dev/null 2>&1; then
    pass "Error output on stdout is structured JSON"
else
    fail "Non-JSON content appears on stdout during error"
    info "Got on stdout: ${invalid_stdout}"
fi

[ "${FAILURES}" -eq 0 ]
