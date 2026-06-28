#!/usr/bin/env bash
# 8原則すべてを実装したサンプル CLI (CI チェックのテスト用)
set -uo pipefail

SCHEMA_VERSION="1.0"
SCRIPT_NAME="$(basename "$0")"

FORMAT="json"
DRY_RUN=false
POSITIONAL=()

while [[ $# -gt 0 ]]; do
    case "$1" in
        --format)      FORMAT="${2:-}";           shift 2 ;;
        --format=*)    FORMAT="${1#--format=}"; shift   ;;
        --dry-run)     DRY_RUN=true;            shift   ;;
        --help|-h)
            printf '{"schema_version":"%s","kind":"Help","usage":"%s <resource> <verb> [options]","resources":["task"]}\n' \
                "${SCHEMA_VERSION}" "${SCRIPT_NAME}"
            exit 0
            ;;
        -*)
            printf '{"schema_version":"%s","kind":"Error","error":"Unknown flag: %s","next_step":"Run %s --help to see available flags","candidates":["--format","--dry-run","--help"]}\n' \
                "${SCHEMA_VERSION}" "$1" "${SCRIPT_NAME}" >&2
            exit 2
            ;;
        *) POSITIONAL+=("$1"); shift ;;
    esac
done

RESOURCE="${POSITIONAL[0]:-}"
VERB="${POSITIONAL[1]:-}"
ARG3="${POSITIONAL[2]:-}"

ok() { printf '%s\n' "$1"; exit 0; }

not_found() {
    local resource="$1" id="$2"
    printf '{"schema_version":"%s","kind":"Error","error":"%s not found: %s","next_step":"Run %s %s list to see available %ss","candidates":[]}\n' \
        "${SCHEMA_VERSION}" "${resource}" "${id}" "${SCRIPT_NAME}" "${resource}" "${resource}" >&2
    exit 3
}

arg_error() {
    local message="$1" next_step="$2"
    printf '{"schema_version":"%s","kind":"Error","error":"%s","next_step":"%s"}\n' \
        "${SCHEMA_VERSION}" "${message}" "${next_step}" >&2
    exit 2
}

case "${RESOURCE}" in
    task)
        case "${VERB}" in
            list)
                if [ "${FORMAT}" = "tsv" ]; then
                    printf "id\tname\tstatus\n1\tExample Task\topen\n"
                    exit 0
                fi
                ok '{"schema_version":"'"${SCHEMA_VERSION}"'","kind":"TaskList","items":[{"id":"1","name":"Example Task","status":"open"}]}'
                ;;
            create)
                if [ "${DRY_RUN}" = "true" ]; then
                    ok '{"schema_version":"'"${SCHEMA_VERSION}"'","kind":"DryRun","dry_run":true,"would_create":{"name":"new-task","status":"open"}}'
                fi
                ok '{"schema_version":"'"${SCHEMA_VERSION}"'","kind":"Task","id":"2","name":"new-task","status":"open"}'
                ;;
            get)
                if [ "${ARG3}" = "nonexistent-id-xyz-999999-abc" ] || [ -z "${ARG3}" ]; then
                    not_found "task" "${ARG3}"
                fi
                printf '{"schema_version":"%s","kind":"Task","id":"%s","name":"Example Task","status":"open"}\n' \
                    "${SCHEMA_VERSION}" "${ARG3}"
                exit 0
                ;;
            describe)
                printf '{"schema_version":"%s","kind":"Schema","resource":"task","verb":"%s","args":[{"name":"--name","type":"string","required":true,"description":"Task name"},{"name":"--status","type":"string","required":false,"description":"Task status (open|closed)"}]}\n' \
                    "${SCHEMA_VERSION}" "${ARG3}"
                exit 0
                ;;
            "")
                arg_error "Missing verb for resource 'task'" "Available verbs: list, create, get, describe"
                ;;
            *)
                arg_error "Unknown verb '${VERB}' for resource 'task'" "Available verbs: list, create, get, describe"
                ;;
        esac
        ;;
    describe)
        printf '{"schema_version":"%s","kind":"Schema","resource":"%s","verb":"%s","args":[{"name":"--name","type":"string","required":true,"description":"Name of the resource"}]}\n' \
            "${SCHEMA_VERSION}" "${VERB}" "${ARG3}"
        exit 0
        ;;
    "")
        printf '{"schema_version":"%s","kind":"Help","usage":"%s <resource> <verb> [options]","resources":["task"]}\n' \
            "${SCHEMA_VERSION}" "${SCRIPT_NAME}"
        exit 0
        ;;
    *)
        arg_error "Unknown resource: ${RESOURCE}" "Available resources: task. Run ${SCRIPT_NAME} --help for usage"
        ;;
esac
