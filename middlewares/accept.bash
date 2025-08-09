function phsh-http-middleware-check-accept {
    local available_content_types=( "${@}" )

    while read -d ';' -r content_type; do
        if [[ "$content_type" =~ "${available_content_types[*]}" ]]; then
            return 0
        fi
    done <<<"${PHSH_REQUEST_HEADERS[accept]:-};"

    phsh-log-debug "Request did not accept any of the available content types. Replying with 406 Not Acceptable."
    PHSH_REPLY_STATUS_CODE=406
    PHSH_REPLY_HEADERS[content-type]=application/json
    PHSH_REPLY_BODY=$(jq -n --arg error "Not Acceptable" '{"error": "\($error)"}')
    return 1
}
