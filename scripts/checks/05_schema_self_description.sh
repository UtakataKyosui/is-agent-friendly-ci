#!/usr/bin/env bash
# Check 05: Schema Self-Description
# CLI は describe コマンド (または相当コマンド) で引数構造を JSON 返却できること。
# 例: "mycli describe task create --format json"
set -uo pipefail

FAILURES=0
describe_found=0
pass() { echo "  ✓ $1"; }
fail() { echo "  ✗ $1"; FAILURES=$((FAILURES + 1)); }
info() { echo "    → $1"; }

# eval を使わず直接コマンドとして実行することでメタキャラクタ挿入を防ぐ
try_describe() {
    local label="$1"; shift
    echo "Trying: ${label}"
    local out code
    out=$("$@" 2>/dev/null); code=$?
    [ "${code}" -eq 0 ] || return 1
    echo "${out}" | jq . > /dev/null 2>&1 || return 1

    pass "Schema description available: ${label}"
    if echo "${out}" | jq -e '.args // .parameters // .options // .flags // .arguments' > /dev/null 2>&1; then
        pass "Schema includes argument definitions field"
    else
        info "Schema JSON returned but lacks a standard argument field (args/parameters/options/flags)"
    fi
    describe_found=1
    return 0
}

# 各パターンを直接コマンドとして試す (eval なし)
# shellcheck disable=SC2086
try_describe "${CLI_CMD} ${DESCRIBE_VERB} ${RESOURCE} ${LIST_VERB} --format json" \
    ${CLI_CMD} ${DESCRIBE_VERB} ${RESOURCE} ${LIST_VERB} --format json ||
try_describe "${CLI_CMD} ${DESCRIBE_VERB} ${RESOURCE} ${CREATE_VERB} --format json" \
    ${CLI_CMD} ${DESCRIBE_VERB} ${RESOURCE} ${CREATE_VERB} --format json ||
try_describe "${CLI_CMD} ${DESCRIBE_VERB} ${RESOURCE} --format json" \
    ${CLI_CMD} ${DESCRIBE_VERB} ${RESOURCE} --format json ||
try_describe "${CLI_CMD} ${DESCRIBE_VERB} --format json" \
    ${CLI_CMD} ${DESCRIBE_VERB} --format json ||
try_describe "${CLI_CMD} ${RESOURCE} ${LIST_VERB} --help --format json" \
    ${CLI_CMD} ${RESOURCE} ${LIST_VERB} --help --format json ||
true

if [ "${describe_found}" -eq 0 ]; then
    fail "No machine-readable schema description found"
    info "Tried: ${CLI_CMD} ${DESCRIBE_VERB} ${RESOURCE} ${LIST_VERB}|${CREATE_VERB} --format json, etc."
fi

[ "${FAILURES}" -eq 0 ]
