#!/bin/zsh

# simple-example.sh - Runs simple example (static two pixels)

set -e

SCRIPT_DIR="$(cd "$(dirname "${(%):-%x}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"
BIN="$PROJECT_ROOT/.build/release/simple-example"

# Default options
HOST="localhost"

# Parse command-line arguments
while [[ $# -gt 0 ]]; do
    case "$1" in
        -h)
            HOST="$2"
            shift 2
            ;;
        -g)
            # simple-example doesn't use -g, just consume it
            shift 2
            ;;
        -t)
            # simple-example doesn't use -t, just consume it
            shift 2
            ;;
        *)
            shift
            ;;
    esac
done

if [[ ! -f "$BIN" ]]; then
    echo "Error: $BIN not found. Build with: swift build -c release"
    exit 1
fi

"$BIN" "$HOST"
