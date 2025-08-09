#!/usr/bin/env bash

source "$(realpath "$BASH_SOURCE/../../phsh.bash")"

function phsh-rest-example-crash {
    return 1
}

phsh-http-serve -c phsh-rest-example-crash
