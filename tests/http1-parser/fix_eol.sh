#!/usr/bin/env bash
# Fixes the end-of-line characters in the requests folder to be consistent with CRLF
set -xeuo pipefail

SOURCE_DIR="$(dirname "$BASH_SOURCE")"

for file in "$SOURCE_DIR"/requests/*.http; do
    # Remove any existing CR characters
    sed -i "" 's/\r//g' "$file"
    # Add CR at the end of each line
    sed -i "" 's/$/\r/' "$file"
done
