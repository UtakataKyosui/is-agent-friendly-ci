#!/usr/bin/env bash
# Check 07: Idempotent Operations / Dry Run
# --dry-run フラグをサポートし、副作用なしで実行内容をプレビューできること。
set -uo pipefail

FAILURES=0
pass() { echo "  ✓ $1"; }
fail() { echo "  ✗ $1"; FAILURES=$((FAILURES + 1)); }
info() { echo "    → $1"; }

echo "Testing: ${CLI_CMD} ${RESOURCE} ${CREATE_VERB} ${CREATE_ARGS} --dry-run"

# eval を使わず word-splitting で実行 (メタキャラクタ挿入を防ぐ)
# shellcheck disable=SC2086
output=$(${CLI_CMD} ${RESOURCE} ${CREATE_VERB} ${CREATE_ARGS} --dry-run 2>&1); code=$?

if [ "${code}" -eq 0 ]; then
    pass "--dry-run flag is accepted and exits successfully"

    # -E フラグで GNU/BSD grep 両方に対応
    if echo "${output}" | grep -qiE "dry.run|would|preview|simul"; then
        pass "Output text indicates simulation (dry run)"
    elif echo "${output}" | jq -e '.dry_run // .preview // .would_create // .simulated // .simulation' > /dev/null 2>&1; then
        pass "JSON output includes dry-run simulation field"
    else
        info "Note: --dry-run succeeded but output doesn't explicitly indicate simulation"
    fi
elif [ "${code}" -eq 2 ]; then
    fail "--dry-run flag not recognized (exit 2 = argument error)"
    info "CLI does not support --dry-run; consider implementing it to allow safe previews"
else
    fail "--dry-run failed with exit code ${code}"
    info "Output: ${output}"
fi

[ "${FAILURES}" -eq 0 ]
