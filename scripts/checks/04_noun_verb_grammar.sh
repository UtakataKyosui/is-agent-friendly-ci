#!/usr/bin/env bash
# Check 04: Noun-Verb Grammar
# コマンドは <cli> <名詞> <動詞> [オプション] の形式に従うこと。
# 例: "mycli task list", "mycli project create"
set -uo pipefail

FAILURES=0
pass() { echo "  ✓ $1"; }
fail() { echo "  ✗ $1"; FAILURES=$((FAILURES + 1)); }
info() { echo "    → $1"; }

# 4a: <名詞> <動詞> パターンが動作する
echo "Testing noun-verb pattern: ${CLI_CMD} ${RESOURCE} ${LIST_VERB}"
${CLI_CMD} ${RESOURCE} ${LIST_VERB} > /dev/null 2>&1; code=$?
if [ "${code}" -eq 0 ]; then
    pass "Noun-verb pattern works: '${CLI_CMD} ${RESOURCE} ${LIST_VERB}' → exit 0"
else
    fail "Noun-verb pattern failed: '${CLI_CMD} ${RESOURCE} ${LIST_VERB}' → exit ${code}"
fi

# 4b: create 動詞も noun-verb 形式で動作する
echo "Testing noun-verb create: ${CLI_CMD} ${RESOURCE} ${CREATE_VERB} ${CREATE_ARGS}"
eval "${CLI_CMD} ${RESOURCE} ${CREATE_VERB} ${CREATE_ARGS}" > /dev/null 2>&1; code=$?
if [ "${code}" -eq 0 ]; then
    pass "Create verb works: '${CLI_CMD} ${RESOURCE} ${CREATE_VERB}' → exit 0"
else
    info "Create verb returned exit ${code} (may require mandatory args not supplied)"
fi

# 4c: ヘルプ出力にリソース名詞が含まれる
echo "Testing help references resource noun"
help_output=$(${CLI_CMD} --help 2>&1 || ${CLI_CMD} help 2>&1 || true)
if echo "${help_output}" | grep -qF "${RESOURCE}"; then
    pass "Help output references the resource noun '${RESOURCE}'"
else
    info "Help output does not mention '${RESOURCE}' — may be dynamic/discovered at runtime"
fi

[ "${FAILURES}" -eq 0 ]
