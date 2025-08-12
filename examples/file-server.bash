#!/usr/bin/env bash

source "$(realpath "$BASH_SOURCE/../../phsh.bash")"
source "$(realpath "$BASH_SOURCE/../../middlewares/accept.bash")"
source "$(realpath "$BASH_SOURCE/../../middlewares/accept.bash")"
source "$(realpath "$BASH_SOURCE/../../middlewares/content-type.bash")"


function phsh-rest-example-file-server {
    # Request middleware

    if [[ "${PHSH_REQUEST_VERB^^}" != GET ]]; then
        phsh-log-error "Unsupported HTTP verb: %s" "$PHSH_REQUEST_VERB"
        PHSH_REPLY_STATUS_CODE=405
        PHSH_REPLY_HEADERS[content-type]="plain/text"
        PHSH_REPLY_BODY="Method Not Allowed"
        return
    fi

    local file="$(realpath ".$PHSH_REQUEST_PATHNAME")"

    if [[ -z "$file" ]]; then
        phsh-log-debug "File not found"
        PHSH_REPLY_STATUS_CODE=404
        PHSH_REPLY_HEADERS[content-type]="plain/text"
        PHSH_REPLY_BODY="File not found"
    elif ! [[ "$file" =~ "$PWD" ]]; then
        phsh-log-error "Attempt to access file outside of the current directory: %s" "$file"
        PHSH_REPLY_STATUS_CODE=403
        PHSH_REPLY_HEADERS[content-type]="plain/text"
        PHSH_REPLY_BODY="Forbidden"
    elif [[ -d "$file" ]]; then
        phsh-log-debug "Serving directory listing for %s" "$file"
        PHSH_REPLY_STATUS_CODE=200
        PHSH_REPLY_HEADERS[content-type]="text/html"
        PHSH_REPLY_BODY="<html>"
        PHSH_REPLY_BODY+="<head><title>Directory listing for $file</title></head>"
        for item in .. "$file"/*; do
            # TODO: Handle HTML and URL invalid characters
            PHSH_REPLY_BODY+="<li><a href=\"$(basename "$item")/\">$(basename "$item")/</a></li>"
        done
        PHSH_REPLY_BODY+="</ul></body></html>"
    elif [[ -f "$file" ]]; then
        phsh-log-debug "Serving regular file: %s" "$file"
        # The file will be served as a stream, so we don't need to set PHSH_REPLY_BODY
        # It will be set by the HTTP server when it sends the response
        PHSH_REPLY_STATUS_CODE=200
        PHSH_REPLY_HEADERS[content-type]="$(file --mime-type -b "$file")"
        PHSH_REPLY_STREAM="$file"
    else
        phsh-log-debug "File not found: %s" "$file"
        PHSH_REPLY_STATUS_CODE=404
        PHSH_REPLY_HEADERS[content-type]="plain/text"
        PHSH_REPLY_BODY="File not found"
    fi
}

phsh-http-serve -c phsh-rest-example-file-server
