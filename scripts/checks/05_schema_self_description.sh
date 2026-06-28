#!/usr/bin/env bash
# Check 05: Schema Self-Description
# CLI は describe コマンド (または相当コマンド) で引数構造を JSON 返却できること。
# 例: "mycli describe task create --format json"
set -uo pipefail

FAILURES=0
pass() { echo "  ✓ $1"; }
fail() { echo "  ✗ $1"; FAILURES=$((FAILURES + 1)); }
info() { echo "    → $1"; }

DESCRIBE_PATTERNS=(
    "${CLI_CMD} ${DESCRIBE_VERB} ${RESOURCE} ${LIST_VERB} --format json"
    "${CLI_CMD} ${DESCRIBE_VERB} ${RESOURCE} ${CREATE_VERB} --format json"
    "${CLI_CMD} ${DESCRIBE_VERB} ${RESOURCE} --format json"
    "${CLI_CMD} ${DESCRIBE_VERB} --format json"
    "${CLI_CMD} ${RESOURCE} ${LIST_VERB} --help --format json"
)

describe_found=0
for pattern in "${DESCRIBE_PATTERNS[@]}"; do
    echo "Trying: ${pattern}"
    output=$(eval "${pattern}" 2>/dev/null); code=$?

    if [ "${code}" -eq 0 ] && echo "${output}" | jq . > /dev/null 2>&1; then
        pass "Schema description available: ${pattern}"

        if echo "${output}" | jq -e '.args // .parameters // .options // .flags // .arguments' > /dev/null 2>&1; then
            pass "Schema includes argument definitions field"
        else
            info "Schema JSON returned but lacks a standard argument field (args/parameters/options/flags)"
        fi
        describe_found=1
        break
    fi
done

if [ "${describe_found}" -eq 0 ]; then
    fail "No machine-readable schema description found"
    info "Tried the following patterns:"
    for p in "${DESCRIBE_PATTERNS[@]}"; do
        info "  ${p}"
    done
fi

[ "${FAILURES}" -eq 0 ]
