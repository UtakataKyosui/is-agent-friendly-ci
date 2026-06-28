#!/usr/bin/env bash
# Check 06: Actionable Errors
# エラーレスポンスに next_step / candidates などのアクション可能なフィールドを含むこと。
set -uo pipefail

FAILURES=0
pass() { echo "  ✓ $1"; }
fail() { echo "  ✗ $1"; FAILURES=$((FAILURES + 1)); }
info() { echo "    → $1"; }

ACTIONABLE_FIELDS=(next_step next_steps candidates hint hints suggestion suggestions fix remedy)

check_actionable() {
    local label="$1"
    local output="$2"

    if [ -z "${output}" ]; then
        info "No output to inspect for: ${label}"
        return
    fi

    if ! echo "${output}" | jq . > /dev/null 2>&1; then
        fail "Error response for '${label}' is not JSON — cannot check for actionable fields"
        return
    fi

    for field in "${ACTIONABLE_FIELDS[@]}"; do
        if echo "${output}" | jq -e ".${field}" > /dev/null 2>&1; then
            pass "Error for '${label}' includes actionable field: '${field}'"
            return
        fi
    done

    fail "Error for '${label}' lacks actionable fields (${ACTIONABLE_FIELDS[*]})"
    info "Error JSON: $(echo "${output}" | jq -c . 2>/dev/null || echo "${output}")"
}

# 6a: 未発見エラー
echo "Testing not-found error: ${CLI_CMD} ${RESOURCE} ${GET_VERB} ${NONEXISTENT_ID}"
stdout_notfound=$(${CLI_CMD} ${RESOURCE} ${GET_VERB} ${NONEXISTENT_ID} 2>/dev/null || true)
stderr_notfound=$(${CLI_CMD} ${RESOURCE} ${GET_VERB} ${NONEXISTENT_ID} 2>&1 >/dev/null || true)
output="${stdout_notfound:-${stderr_notfound}}"
check_actionable "${CLI_CMD} ${RESOURCE} ${GET_VERB} ${NONEXISTENT_ID}" "${output}"

# 6b: 引数エラー
echo "Testing argument error: ${CLI_CMD} ${INVALID_ARGS}"
stdout_invalid=$(${CLI_CMD} ${INVALID_ARGS} 2>/dev/null || true)
stderr_invalid=$(${CLI_CMD} ${INVALID_ARGS} 2>&1 >/dev/null || true)
output="${stdout_invalid:-${stderr_invalid}}"
check_actionable "${CLI_CMD} ${INVALID_ARGS}" "${output}"

[ "${FAILURES}" -eq 0 ]
