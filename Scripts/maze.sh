#!/bin/zsh

# maze.sh - Runs maze generation and solving animation

set -e

SCRIPT_DIR="$(cd "$(dirname "${(%):-%x}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"
BIN="$PROJECT_ROOT/.build/release/maze"

# Default options
HOST="localhost"
GEOMETRY="45x35+0+0"
TIMEOUT_ARG=15

# Parse command-line arguments
while [[ $# -gt 0 ]]; do
    case "$1" in
        -h)
            HOST="$2"
            shift 2
            ;;
        -g)
            GEOMETRY="$2"
            shift 2
            ;;
        -t)
            TIMEOUT_ARG="$2"
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

"$BIN" -h "$HOST" -g "$GEOMETRY" -t $TIMEOUT_ARG -d 20
