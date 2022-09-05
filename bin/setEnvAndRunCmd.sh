#! /bin/bash --

source "$(dirname "$0")/../settings64.sh" 1>/dev/null 2>&1
exec "$@"
