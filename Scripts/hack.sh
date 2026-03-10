#!/bin/zsh

# hack.sh - Runs hack demo with different text strings

set -e

SCRIPT_DIR="$(cd "$(dirname "${(%):-%x}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"
HACK_BIN="$PROJECT_ROOT/.build/release/hack"
TEXTS=(HACK CODE FUN FIRE GLOW)

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

if [[ ! -f "$HACK_BIN" ]]; then
    echo "Error: $HACK_BIN not found. Build with: swift build -c release"
    exit 1
fi

echo "Running hack with different text (5 seconds each)..."
echo "Press Ctrl+C to stop"
echo ""

iteration=1
while true; do
    echo "=== Loop $iteration ==="
    for text in "${TEXTS[@]}"; do
        echo "▶ Text: $text"
        "$HACK_BIN" -h "$HOST" -g "$GEOMETRY" -t $TIMEOUT_ARG -d 50 "$text"
        echo ""
    done
    ((iteration++))
done
