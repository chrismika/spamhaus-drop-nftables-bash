#!/bin/bash
set -uo pipefail

# --- Parameter Defaults ---
readonly DEFAULT_NFT_CMD="/usr/sbin/nft"
readonly DEFAULT_JQ_CMD="/usr/bin/jq"
readonly DEFAULT_CURL_CMD="/usr/bin/curl"
readonly DEFAULT_LOG_PREFIX="DROP_List_Block"
readonly DEFAULT_LOG_LEVEL="warn"
readonly DEFAULT_DEBUG=false
readonly DEFAULT_QUIET=false
readonly DEFAULT_LOG_FLAG=false
readonly DEFAULT_MAX_RETRY=5
readonly DEFAULT_RETRY_DELAY=5

# --- Working Variables (mutable) ---
NFT_CMD="${DEFAULT_NFT_CMD}"
JQ_CMD="${DEFAULT_JQ_CMD}"
CURL_CMD="${DEFAULT_CURL_CMD}"
LOG_PREFIX="${DEFAULT_LOG_PREFIX}"
LOG_LEVEL="${DEFAULT_LOG_LEVEL}"
DEBUG=${DEFAULT_DEBUG}
QUIET=${DEFAULT_QUIET}
LOG_FLAG=${DEFAULT_LOG_FLAG}
MAX_RETRY=${DEFAULT_MAX_RETRY}
RETRY_DELAY=${DEFAULT_RETRY_DELAY}

# --- Global Constants ---
readonly DROP_LIST_URL="https://www.spamhaus.org/drop/drop.txt"
readonly TABLE_NAME="table-spamhaus-drop-list"
readonly SET_NAME="set-spamhaus-drop-list-$(date +%Y%m%d%H%M%S)"
readonly CHAIN_IN_NAME="chain-drop-list-in"
readonly CHAIN_OUT_NAME="chain-drop-list-out"
readonly LOG_DATE_FORMAT="+%b %d %H:%M:%S"
readonly USAGE="Usage: $0 [options]"

parse_args() {
    while [[ $# -gt 0 ]]; do
        case "${1}" in
            -d)
                DEBUG=true
                shift
                ;;
            -l)
                LOG_FLAG=true
                if ! log_setup; then return 1; fi
                shift
                ;;
            -q)
                QUIET=true
                shift
                ;;
            --curl-cmd)
                CURL_CMD="${2}"
                shift 2
                ;;
            --log-level)
                LOG_LEVEL="${2}"
                if ! log_setup; then return 1; fi
                shift 2
                ;;
            --log-prefix)
                LOG_PREFIX="${2}"
                if ! log_setup; then return 1; fi
                shift 2
                ;;
            --jq-cmd)
                JQ_CMD="${2}"
                shift 2
                ;;
            --max-retry)
                if [[ ! "${2}" =~ ^[0-9]+$ ]]; then
                    error "--curl-max-retry must be a non-negative integer"
                    return 1
                fi
                MAX_RETRY=${2}
                shift 2
                ;;
            --nft-cmd)
                NFT_CMD="${2}"
                shift 2
                ;;
            --retry-delay)
                if [[ ! "${2}" =~ ^[1-9][0-9]*$ ]]; then
                    error "--curl-retry-delay must be a positive integer"
                    return 1
                fi
                RETRY_DELAY=${2}
                shift 2
                ;;

            -h|--help)
                echo "${USAGE}"
                echo
                echo "Deploy Spamhaus' DROP list to Linux using bash and nftables."
                echo
                echo "Options:"
                echo "  -d                        Turn on debug for error messages"
                echo "  -l                        Log rule matches"
                echo "  -q                        Suppress final success message"
                echo "      --curl-cmd PATH       Path to curl executable"
                echo "                            (default: $DEFAULT_CURL_CMD)"
                echo "      --log-level LEVEL     Set the filter's log level"
                echo "                            (default: ${DEFAULT_LOG_LEVEL})"
                echo "      --log-prefix PREFIX   Set the filter's log prefix"
                echo "                            (default: \"${DEFAULT_LOG_PREFIX}\")"
                echo "      --jq-cmd PATH         Path to jq executable"
                echo "                            (default: ${DEFAULT_JQ_CMD})"
                echo "      --max-retry INT       Set the max number of download retries"
                echo "                            (default: ${DEFAULT_MAX_RETRY})"
                echo "      --nft-cmd PATH        Path to nft executable"
                echo "                            (default: ${DEFAULT_NFT_CMD})"
                echo "      --retry-delay INT     Set the delay between download retries"
                echo "                            (default: ${DEFAULT_RETRY_DELAY})"
                echo "  -h, --help                Print this help message"
                return 1
                ;;
            *)
                echo "Unknown argument: ${1}"
                echo "${USAGE}"
                return 1
                ;;
        esac
    done
}

log_setup () {
    local -rA LOG_LEVEL_OPTIONS=(["emerg"]=1 ["alert"]=1 ["crit"]=1 ["err"]=1 ["warn"]=1 ["notice"]=1  ["info"]=1  ["debug"]=1)
    if ! [[ -v LOG_LEVEL_OPTIONS["${LOG_LEVEL}"] ]]; then
        error "Unknown log level: ${LOG_LEVEL}"
        return 1
    fi
    LOG_TXT="log prefix \"${LOG_PREFIX} \" level ${LOG_LEVEL}"
}

error () {
    local message="${1}"
    local error_message="${2:-}"
    echo -n "$(date "${LOG_DATE_FORMAT}") [error]: ${message}" >&2
    if ${DEBUG} && [[ -n "${error_message}" ]]; then
        echo -n ": ${error_message}" >&2
    fi
    echo >&2
}

check_requirements () {
    if [[ ${EUID} -ne 0 ]]; then
        error "Incorrect user: must be root"
        return 1
    fi
    if ! command -v "${NFT_CMD}" >/dev/null 2>&1; then
        error "nft command not present"
        return 1
    fi
    if ! command -v "${JQ_CMD}" >/dev/null 2>&1; then
        error "jq command not present"
        return 1
    fi
    if ! command -v "${CURL_CMD}" >/dev/null 2>&1; then
        error "curl command not present"
        return 1
    fi
}

ensure_table () {
    if ${NFT_CMD} list table inet "${TABLE_NAME}" >/dev/null 2>&1; then
        return 0
    else
        local error_message
        error_message=$(${NFT_CMD} add table inet "${TABLE_NAME}" 2>&1 >/dev/null)
        if [[ $? -ne 0 ]]; then
            error "failed to add table ${TABLE_NAME}" "${error_message}"
            return 1
        fi
    fi
}

ensure_set () {
  if ${NFT_CMD} list set inet "${TABLE_NAME}" "${SET_NAME}" >/dev/null 2>&1; then
      return 0
  else
      local error_message
      error_message=$(${NFT_CMD} add set inet "${TABLE_NAME}" "${SET_NAME}" \
        "{ type ipv4_addr; flags interval; auto-merge; }" 2>&1 >/dev/null)
        if [[ $? -ne 0 ]]; then
            error "failed to add set ${SET_NAME}" "${error_message}"
            return 1
        fi
  fi
}

populate_set () {
    local curl_output
    for ((i = 0; i < MAX_RETRY; i++)); do
        curl_output=$(curl -fSLs "${DROP_LIST_URL}" 2>&1) 
        if [[ $? -ne 0 ]]; then
            if [[ ${i} -eq $((MAX_RETRY - 1)) ]]; then
                error "failed to download ${DROP_LIST_URL}: ${curl_output}"
                return 1
            else
                error "failed to download ${DROP_LIST_URL} (retrying - $((i + 1))/${MAX_RETRY}): ${curl_output}"
                sleep "${RETRY_DELAY}"
            fi
        else
            break
        fi
    done
    local error_message
    error_message=$(${NFT_CMD} add element inet "${TABLE_NAME}" "${SET_NAME}" \
      "{ $(printf "%s\n" "$curl_output" | grep -v "^;" | awk '{print $1}' | paste -sd "," -) }" 2>&1 >/dev/null)
    if [[ $? -ne 0 ]]; then
        error "failed to add elements to set ${SET_NAME}" "${error_message}"
        return 1
    fi
}

ensure_chain () {
    local chain_name=${1}
    local hook_point
    case "${chain_name}" in
        *-in)
            hook_point="input"
            ;;
        *-out)
            hook_point="output"
            ;;
        *)
            error "Invalid chain name format: ${chain_name}"
            return 1
            ;;
    esac
    local error_message
    if ! ${NFT_CMD} list chain inet "${TABLE_NAME}" "${chain_name}" >/dev/null 2>&1; then
        error_message=$(${NFT_CMD} add chain inet "${TABLE_NAME}" "${chain_name}" \
          "{ type filter hook ${hook_point} priority filter -1; policy accept; }" 2>&1 >/dev/null) 
        if [[ $? -ne 0 ]]; then
            error "failed to add chain ${chain_name}" "${error_message}"
        fi
    fi
}

ensure_rule () {
    local chain_name=${1}
    local address
    case "${chain_name}" in
        *-in)
            address="s"
            ;;
        *-out)
            address="d"
            ;;
        *)
            error "Invalid chain name format: ${chain_name}"
            return 1
            ;;
    esac
    local error_message
    local filter="ip ${address}addr @${SET_NAME}"
    local search_filter="${filter}( log( prefix \".*\")?( level .*)?)?"
    if ${LOG_FLAG}; then filter="${filter} ${LOG_TXT}"; fi
    if ! ${NFT_CMD} list chain inet "${TABLE_NAME}" "${chain_name}" 2>/dev/null | \
      grep -qE "${search_filter} drop"; then 
        error_message=$(${NFT_CMD} add rule inet "${TABLE_NAME}" "${chain_name}" "${filter}" drop 2>&1 >/dev/null)
        if [[ $? -ne 0 ]]; then
          error "failed to add rule to ${chain_name}" "${error_message}"
          return 1
        fi
    fi
}

delete_stale_rules () {
    local chain_name=${1}
    for i in $(${NFT_CMD} -j list chain inet "${TABLE_NAME}" "${chain_name}" 2>/dev/null | \
      ${JQ_CMD} -r '.nftables[] | select(.rule) | 
      select( all(.rule.expr[]?; .match.right != ("@" + "'"${SET_NAME}"'"))) | .rule.handle'); do
        local error_message
        error_message=$(${NFT_CMD} delete rule inet "${TABLE_NAME}" "${chain_name}" handle "${i}" 2>&1 >/dev/null)
        if [[ $? -ne 0 ]]; then
          error "failed to delete rule handle ${i} from ${chain_name}" "${error_message}"
          return 1
        fi
    done
}

delete_stale_sets () {
    for i in $(${NFT_CMD} -j list sets | ${JQ_CMD} -r '.nftables[] | select(.set) | select(.set.table == "'"${TABLE_NAME}"'")
      | select(.set.name != "'"${SET_NAME}"'") | .set.handle'); do
        local error_message
        error_message=$(${NFT_CMD} delete set inet "${TABLE_NAME}" handle "${i}" 2>&1 >/dev/null) 
        if [[ $? -ne 0 ]]; then
          error "failed to delete set handle ${i}" "${error_message}"
        fi
    done
}

main () {
    if ! check_requirements; then exit 1; fi
    if ! ensure_table; then exit 1; fi
    if ! ensure_set; then exit 1; fi
    if ! populate_set; then exit 1; fi
    for i in "${CHAIN_IN_NAME}" "${CHAIN_OUT_NAME}"; do
        if ! ensure_chain "${i}"; then exit 1; fi
        if ! ensure_rule "${i}"; then exit 1; fi
        if ! delete_stale_rules "${i}"; then exit 1; fi
    done
    if ! delete_stale_sets; then exit 1; fi
    if ! $QUIET; then echo "${0} completed successfully (${SET_NAME})"; fi
}
if ! parse_args "$@"; then exit 1; fi
main
