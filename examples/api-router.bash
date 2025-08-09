#!/usr/bin/env bash

source "$(realpath "$BASH_SOURCE/../../phsh.bash")"
source "$(realpath "$BASH_SOURCE/../../middlewares/accept.bash")"
source "$(realpath "$BASH_SOURCE/../../middlewares/content-type.bash")"

function phsh-rest-example-api-router-get-api-v1-hello {
    local name="${PHSH_REQUEST_SEARCH_PARAMS[name]:-World}"

    PHSH_REPLY_STATUS_CODE=200
    PHSH_REPLY_HEADERS[content-type]="application/json"
    PHSH_REPLY_BODY="$(jq -n --arg name "$name" --arg ip "$PHSH_REQUEST_IP" '{"message": "Hello, \($name)!", "ip": "\($ip)"}')"
}

function phsh-rest-example-api-router {
    # Request middleware
    phsh-http-middleware-add-content-type "application/json"
    phsh-http-middleware-check-accept "application/json" "application/vnd.api+json" "*/*"

    local relative_path="${PHSH_REQUEST_PATHNAME#/}"
    local handler="phsh-rest-example-api-router-${PHSH_REQUEST_VERB,,}-${relative_path//\//-}"

    if [[ "$(type -t "$handler")" == function ]]; then
        phsh-log-debug "Routing request to handler: name=%s" "$handler"
        "$handler" "$@"
    else
        phsh-log-debug "No handler found to handle the request. Sending not found (name=%s)" "$handler"
        PHSH_REPLY_STATUS_CODE=404
        PHSH_REPLY_HEADERS[content-type]="application/json"
        PHSH_REPLY_BODY="$(jq -n --arg error "Not Found" '{"error": $error}')"
    fi
}

phsh-http-serve -c phsh-rest-example-api-router
