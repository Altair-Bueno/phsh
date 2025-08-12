#!/usr/bin/env bash

SOURCE_DIR="$(dirname "$BASH_SOURCE")"

# set -x
source "$SOURCE_DIR/../../phsh.bash"

function dump-vars {
    for var_name in "$@" ; do
        declare -p "$var_name"
    done
}

function main {
    for expected in "$SOURCE_DIR"/expected/* ; do
        local test_name="${expected##*/}"
        local request="$SOURCE_DIR/requests/${test_name}.http"

        echo "Running test: $test_name"

        declare -A PHSH_REQUEST_HEADERS=()
        declare -A PHSH_REQUEST_SEARCH_PARAMS=()
        declare -A PHSH_REPLY_HEADERS=()

        phsh-http-request-parser < "$request"

        diff --side-by-side --suppress-common-lines --width 99999 \
            <(dump-vars "${!PHSH_REQUEST@}" | sort) \
            <(cat "$expected" | sort)

    done
}

main "$@"
