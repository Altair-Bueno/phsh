#!/usr/bin/env bash

source "$(realpath "$BASH_SOURCE/../../phsh.bash")"
source "$(realpath "$BASH_SOURCE/../../middlewares/accept.bash")"
source "$(realpath "$BASH_SOURCE/../../middlewares/accept.bash")"
source "$(realpath "$BASH_SOURCE/../../middlewares/content-type.bash")"


function phsh-rest-example-file-server {
    # Request middleware
    # phsh-http-middleware-add-content-type "application/json"
    # phsh-http-middleware-check-accept "application/json" "application/vnd.api+json" "*/*"

    local file="$(realpath ".$PHSH_REQUEST_PATHNAME")"

    if [[ -z "$file" ]]; then
        phsh-log-debug "File not found"
        PHSH_REPLY_STATUS_CODE=404
        PHSH_REPLY_HEADERS[content-type]="plain/text"
        PHSH_REPLY_BODY="File not found"
        return
    elif ! [[ "$file" =~ "$PWD" ]]; then
        phsh-log-error "Attempt to access file outside of the current directory: %s" "$file"
        PHSH_REPLY_STATUS_CODE=403
        PHSH_REPLY_HEADERS[content-type]="plain/text"
        PHSH_REPLY_BODY="Forbidden"
        return
    fi

    PHSH_REPLY_HEADERS[content-type]="$(file --mime-type -b "$file")"
    PHSH_REPLY_STREAM="$file"
    PHSH_REPLY_STATUS_CODE=200
}

phsh-http-serve -c phsh-rest-example-file-server
