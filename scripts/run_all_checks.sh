#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CHECKS_DIR="${SCRIPT_DIR}/checks"

# Validate required env vars
if [ -z "${CLI_CMD:-}" ]; then
    echo "Error: CLI_CMD environment variable is required." >&2
    exit 1
fi
if [ -z "${RESOURCE:-}" ]; then
    echo "Error: RESOURCE environment variable is required." >&2
    exit 1
fi

# Defaults for optional env vars
export GET_VERB="${GET_VERB:-get}"
export DESCRIBE_VERB="${DESCRIBE_VERB:-describe}"
export CREATE_ARGS="${CREATE_ARGS:-}"
export INVALID_ARGS="${INVALID_ARGS:---invalid-flag-xyz-does-not-exist-abc123}"
export NONEXISTENT_ID="${NONEXISTENT_ID:-nonexistent-id-xyz-999999-abc}"
export SEVERITY="${SEVERITY:-required}"

# Validate SEVERITY value
case "${SEVERITY}" in
    required|recommended|all) ;;
    *)
        echo "Error: Invalid SEVERITY '${SEVERITY}'. Must be one of: required, recommended, all" >&2
        exit 1
        ;;
esac

# Result tracking
PASS_COUNT=0
FAIL_COUNT=0
CHECK_IDS=()
CHECK_NAMES=()
CHECK_SEVERITIES=()
CHECK_RESULTS=()

run_check() {
    local id="$1"
    local name="$2"
    local severity="$3"
    local script="${CHECKS_DIR}/${4}"

    echo ""
    printf '━%.0s' {1..60}; echo
    printf " [%s] %s\n" "$id" "$name"
    printf " Severity: %s\n" "$severity"
    printf '━%.0s' {1..60}; echo

    local result
    if bash "${script}" 2>&1; then
        result="PASS"
        PASS_COUNT=$((PASS_COUNT + 1))
        echo "✓ CHECK ${id} PASSED"
    else
        result="FAIL"
        FAIL_COUNT=$((FAIL_COUNT + 1))
        echo "✗ CHECK ${id} FAILED"
    fi

    CHECK_IDS+=("$id")
    CHECK_NAMES+=("$name")
    CHECK_SEVERITIES+=("$severity")
    CHECK_RESULTS+=("$result")
}

echo "════════════════════════════════════════════════════════════"
echo " Agent-Friendly CLI Check"
echo " Ref: https://zenn.dev/assign/articles/b3d1d07d385b87"
echo "════════════════════════════════════════════════════════════"
echo " CLI Command : ${CLI_CMD}"
echo " Resource    : ${RESOURCE}"
echo " Severity    : ${SEVERITY}"
echo "════════════════════════════════════════════════════════════"

run_check "01" "Structured Output (JSON envelope)"          "required"    "01_structured_output.sh"
run_check "02" "Semantic Exit Codes"                        "required"    "02_semantic_exit_codes.sh"
run_check "03" "Non-Interactive Mode"                       "required"    "03_non_interactive_mode.sh"
run_check "04" "Noun-Verb Grammar"                         "required"    "04_noun_verb_grammar.sh"
run_check "05" "Schema Self-Description"                    "recommended" "05_schema_self_description.sh"
run_check "06" "Actionable Errors (next_step / candidates)" "recommended" "06_actionable_errors.sh"
run_check "07" "Idempotent Operations (--dry-run)"         "recommended" "07_idempotent_dry_run.sh"
run_check "08" "Composability (--format flag)"             "recommended" "08_composability.sh"

# Print summary table
echo ""
echo "════════════════════════════════════════════════════════════"
echo " SUMMARY"
echo "════════════════════════════════════════════════════════════"
for i in "${!CHECK_IDS[@]}"; do
    result="${CHECK_RESULTS[$i]}"
    severity="${CHECK_SEVERITIES[$i]}"
    name="${CHECK_NAMES[$i]}"
    if [ "$result" = "PASS" ]; then
        printf " ✓  [%s] %-48s [%s]\n" "${CHECK_IDS[$i]}" "$name" "$severity"
    else
        printf " ✗  [%s] %-48s [%s]\n" "${CHECK_IDS[$i]}" "$name" "$severity"
    fi
done
echo ""
printf " Total: %d passed, %d failed\n" "$PASS_COUNT" "$FAIL_COUNT"
echo "════════════════════════════════════════════════════════════"

# GitHub Step Summary
if [ -n "${GITHUB_STEP_SUMMARY:-}" ]; then
    {
        echo "## Agent-Friendly CLI Check Results"
        echo ""
        echo "**CLI:** \`${CLI_CMD}\` | **Resource:** \`${RESOURCE}\` | **Severity:** \`${SEVERITY}\`"
        echo ""
        echo "| # | Check | Severity | Result |"
        echo "|---|-------|----------|--------|"
        for i in "${!CHECK_IDS[@]}"; do
            result="${CHECK_RESULTS[$i]}"
            severity="${CHECK_SEVERITIES[$i]}"
            name="${CHECK_NAMES[$i]}"
            icon=$( [ "$result" = "PASS" ] && echo "✅" || echo "❌" )
            echo "| ${CHECK_IDS[$i]} | ${name} | \`${severity}\` | ${icon} ${result} |"
        done
        echo ""
        echo "**${PASS_COUNT} passed, ${FAIL_COUNT} failed**"
    } >> "$GITHUB_STEP_SUMMARY"
fi

# Write action outputs
if [ -n "${GITHUB_OUTPUT:-}" ]; then
    {
        echo "passed=${PASS_COUNT}"
        echo "failed=${FAIL_COUNT}"
    } >> "$GITHUB_OUTPUT"
fi

# Determine whether to fail based on severity setting
SHOULD_FAIL=0
for i in "${!CHECK_RESULTS[@]}"; do
    if [ "${CHECK_RESULTS[$i]}" = "FAIL" ]; then
        severity="${CHECK_SEVERITIES[$i]}"
        case "${SEVERITY}" in
            "required")
                [ "$severity" = "required" ] && SHOULD_FAIL=1
                ;;
            "recommended")
                { [ "$severity" = "required" ] || [ "$severity" = "recommended" ]; } && SHOULD_FAIL=1
                ;;
            "all")
                SHOULD_FAIL=1
                ;;
        esac
    fi
done

if [ "$SHOULD_FAIL" -eq 1 ]; then
    echo ""
    echo "FAILED: CLI does not meet agent-friendly requirements at severity '${SEVERITY}'"
    exit 1
fi

echo ""
echo "SUCCESS: CLI meets agent-friendly requirements at severity '${SEVERITY}'"
exit 0
