set -euo pipefail

# Log framework
###############################################################################
declare -gA PHSH_LOG_LEVEL_MAP=()
PHSH_LOG_LEVEL_MAP[ERROR]=4
PHSH_LOG_LEVEL_MAP[WARN]=3
PHSH_LOG_LEVEL_MAP[INFO]=2
PHSH_LOG_LEVEL_MAP[DEBUG]=1

function phsh-fatal {
    PHSH_META_CALLER="${PHSH_META_CALLER:-"${FUNCNAME[1]}"}"  phsh-log-error "$@"
    return 1
}

function phsh-log {
    local log_level="${1^^}" format_string="${2}" format_args=("${@:3}")

    local phsh_log_level="${PHSH_LOG_LEVEL:-INFO}"
    phsh_log_level="${phsh_log_level^^}"

    if [[ "${PHSH_LOG_LEVEL_MAP["$log_level"]}" -ge "${PHSH_LOG_LEVEL_MAP["$phsh_log_level"]}" ]]; then
        local funcname_caller="${PHSH_META_CALLER:-"${FUNCNAME[1]}"}"
        printf "%s %s [%s]\t$format_string\n" \
            "$(TZ=utc date -Iseconds)" \
            "${log_level}" \
            "${funcname_caller}" \
            "${format_args[@]}" \
            1>&2
    fi
}

function phsh-log-error { PHSH_META_CALLER="${PHSH_META_CALLER:-"${FUNCNAME[1]}"}"  phsh-log "error" "$@"; }
function phsh-log-warn { PHSH_META_CALLER="${PHSH_META_CALLER:-"${FUNCNAME[1]}"}"  phsh-log "warn" "$@" ; }
function phsh-log-info { PHSH_META_CALLER="${PHSH_META_CALLER:-"${FUNCNAME[1]}"}"  phsh-log "info" "$@" ; }
function phsh-log-debug { PHSH_META_CALLER="${PHSH_META_CALLER:-"${FUNCNAME[1]}"}"  phsh-log "debug" "$@" ; }

# URL utilities
###############################################################################

function phsh-url-decode {
    local url="$1"

    local decoded="${url//%/\\x}"
    decoded="${decoded//\+/ }"
    printf "%b" "$decoded"
}

function phsh-url-encode {
    local url="$1"

    local encoded="${url// /+}"
    encoded="${encoded//\//%2F}"
    encoded="${encoded//:/%3A}"
    encoded="${encoded//?/%3F}"
    encoded="${encoded//&/%26}"
    encoded="${encoded//=/\%3D}"
    printf "%s" "$encoded"
}

# HTTP
###############################################################################

function phsh-http-reply-builder {
    PHSH_REPLY_STATUS_CODE="${PHSH_REPLY_STATUS_CODE:-200}"

    PHSH_REPLY_HEADERS[connection]=close
    PHSH_REPLY_HEADERS[date]=$(TZ=utc date -Iseconds)
    PHSH_REPLY_HEADERS[server]=phsh-http-server

    if [[ "${PHSH_REPLY_STREAM:+x}" = x ]]; then
        phsh-log-debug "Building HTTP reply from stream (stream=%s)" "$PHSH_REPLY_STREAM"

        PHSH_REPLY_HEADERS[transfer-encoding]=chunked
        # Prepare the reply metadata
        printf "HTTP/1.1 %s %s\r\n" "$PHSH_REPLY_STATUS_CODE"
        # Add the reply headers
        for header_key in "${!PHSH_REPLY_HEADERS[@]}"; do
            local header_value="${PHSH_REPLY_HEADERS["$header_key"]}"
            printf "%s: %s\r\n" "$header_key" "$header_value"
        done
        printf "\r\n"

        # Stream the body
        while IFS=$'\n' read -r chunk; do
            local chunk="$chunk"$'\n'
            local chunk_size="${#chunk}"
            printf "%x\r\n%s\r\n" "$chunk_size" "$chunk"
        done < "${PHSH_REPLY_STREAM}"

        printf "0\r\n\r\n"  # End of chunks
    else
        PHSH_REPLY_BODY="${PHSH_REPLY_BODY:-}"
        phsh-log-debug "Building HTTP reply with in-memory body (size=%x)" "${#PHSH_REPLY_BODY}"

        PHSH_REPLY_HEADERS[content-length]="${#PHSH_REPLY_BODY}"
        # Prepare the reply metadata
        printf "HTTP/1.1 %s %s\r\n" "$PHSH_REPLY_STATUS_CODE"
        # Add the reply headers
        for header_key in "${!PHSH_REPLY_HEADERS[@]}"; do
            local header_value="${PHSH_REPLY_HEADERS["$header_key"]}"
            printf "%s: %s\r\n" "${header_key,,}" "${header_value,,}"
        done
        printf "\r\n"
        printf "%s" "${PHSH_REPLY_BODY}"
    fi
}

function phsh-http-request-parser {
    local header_line header_key header_value query_key query_value
    # Get the request metadata
    IFS=" " read -d $'\r\n' -r PHSH_REQUEST_VERB PHSH_REQUEST_PATH PHSH_REQUEST_VERSION
    case "$PHSH_REQUEST_VERSION" in
        HTTP/1.0|HTTP/1.1) ;;
        *) phsh-fatal "Unsupported HTTP version: '%s'" "$PHSH_REQUEST_VERSION" ;;
    esac

    # Get the request headers
    while read -d $'\r\n' -r header_line; do
        if [[ -z "$header_line" ]]; then
            break  # End of headers
        fi
        IFS=":" read -r header_key header_value <<< "$header_line"
        header_key="${header_key,,}"
        header_value="${header_value%%[[:space:]]}"
        header_value="${header_value##[[:space:]]}"
        PHSH_REQUEST_HEADERS["$header_key"]="$header_value"
    done

    # Get the request body
    IFS="" read -r PHSH_REQUEST_BODY

    # Break the path into components
    PHSH_REQUEST_PATHNAME="${PHSH_REQUEST_PATH%%\?*}"
    PHSH_REQUEST_PATHNAME="$(phsh-url-decode "$PHSH_REQUEST_PATHNAME")"

    if [[ "$PHSH_REQUEST_PATH" =~ "#" ]]; then
        PHSH_REQUEST_HASH="#${PHSH_REQUEST_PATH#*#}"
        PHSH_REQUEST_HASH="$(phsh-url-decode "$PHSH_REQUEST_HASH")"
    else
        PHSH_REQUEST_HASH=""
    fi

    if [[ "$PHSH_REQUEST_PATH" =~ "?" ]]; then
        PHSH_REQUEST_SEARCH="?${PHSH_REQUEST_PATH#*\?}"
        PHSH_REQUEST_SEARCH="${PHSH_REQUEST_SEARCH%"$PHSH_REQUEST_HASH"}"

        while IFS="=" read -d '&' -r query_key query_value ; do
            query_key="$(phsh-url-decode "$query_key")"
            query_value="$(phsh-url-decode "${query_value:-}")"
            PHSH_REQUEST_SEARCH_PARAMS["$query_key"]="$query_value"
        done <<<"${PHSH_REQUEST_SEARCH#\?}&"
    else
        PHSH_REQUEST_SEARCH=""
        PHSH_REQUEST_SEARCH_PARAMS=()
    fi
}

function phsh-http-process {
    declare -A PHSH_REQUEST_HEADERS=()
    declare -A PHSH_REQUEST_SEARCH_PARAMS=()
    declare -A PHSH_REPLY_HEADERS=()

    phsh-log-debug "Received a new request from %s" "$PHSH_REQUEST_IP"

    phsh-http-request-parser <&$PHSH_SOCKET
    "$command" || {
        # In case the error was unintentional, we still want to reply. With this, we
        # can ensure that the server does not crash and that the client receives still receives
        # a reply.
        phsh-log-error "Command '%s' failed to process the given request" "$command"
        : ${PHSH_REPLY_STATUS_CODE:=500} ${PHSH_REPLY_BODY:="Internal Server Error"}
    }
    phsh-http-reply-builder >&$PHSH_SOCKET
    phsh-log-debug "Reply sent to %s. Closing the connection" "$PHSH_REQUEST_IP"

    exec {PHSH_SOCKET}<&-
}

function phsh-http-serve {
    local host=127.0.0.1 port=8080 command

    while getopts ":h:p:c:" opt; do
        case "$opt" in
            h) host="$OPTARG" ;;
            p) port="$OPTARG" ;;
            c) command="$OPTARG" ;;
            \?) phsh-fatal "Invalid option: %s" "$OPTARG" ;;
            :) phsh-fatal "Option -%s requires an argument." "$OPTARG" ;;
        esac
    done
    enable accept

    phsh-log-info "Listening at http://%s:%s" "$host" "$port"

    while true; do
        accept -b "$host" -v PHSH_SOCKET -r PHSH_REQUEST_IP "$port"
        phsh-http-process "$command" &
        # Close the socket file descriptor on the parent process
        exec {PHSH_SOCKET}<&-
    done
}
