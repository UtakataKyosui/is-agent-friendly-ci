#!/usr/bin/env bash
# Check 08: Composability
# --format json および --format tsv をサポートし、jq や awk などと組み合わせ可能なこと。
set -uo pipefail

FAILURES=0
pass() { echo "  ✓ $1"; }
fail() { echo "  ✗ $1"; FAILURES=$((FAILURES + 1)); }
info() { echo "    → $1"; }

# 8a: --format json フラグ
echo "Testing: ${CLI_CMD} ${RESOURCE} ${LIST_VERB} --format json"
json_output=$(${CLI_CMD} ${RESOURCE} ${LIST_VERB} --format json 2>/dev/null); code=$?

if [ "${code}" -eq 0 ] && echo "${json_output}" | jq . > /dev/null 2>&1; then
    pass "--format json produces valid JSON"
else
    # デフォルト出力が JSON であれば合格とする
    default_output=$(${CLI_CMD} ${RESOURCE} ${LIST_VERB} 2>/dev/null)
    if echo "${default_output}" | jq . > /dev/null 2>&1; then
        pass "Default output is JSON (--format json may be implicit)"
    else
        fail "--format json not supported or does not produce valid JSON"
        info "Exit: ${code}, Output: ${json_output}"
    fi
fi

# 8b: --format tsv フラグ (オプション)
echo "Testing: ${CLI_CMD} ${RESOURCE} ${LIST_VERB} --format tsv"
tsv_output=$(${CLI_CMD} ${RESOURCE} ${LIST_VERB} --format tsv 2>/dev/null); tsv_code=$?
if [ "${tsv_code}" -eq 0 ]; then
    pass "--format tsv is supported"
else
    info "Note: --format tsv not supported (optional but improves composability with awk/cut)"
fi

# 8c: JSON 出力が jq にパイプできる
echo "Testing: output is pipeable with jq"
piped=$(${CLI_CMD} ${RESOURCE} ${LIST_VERB} 2>/dev/null | jq . 2>/dev/null); pipe_code=$?
if [ "${pipe_code}" -eq 0 ]; then
    pass "Output is pipeable and processable with jq"
else
    info "Output cannot be processed by jq via pipe"
fi

[ "${FAILURES}" -eq 0 ]
