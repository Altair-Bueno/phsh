function phsh-http-middleware-add-content-type {
    local content_type="$1"

    PHSH_REPLY_HEADERS[content-type]="$content_type"
}
