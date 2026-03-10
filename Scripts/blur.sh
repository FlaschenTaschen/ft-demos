#!/bin/zsh

# blur.sh - Runs blur demo with different pattern variations

set -e

SCRIPT_DIR="$(cd "$(dirname "${(%):-%x}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"
BLUR_BIN="$PROJECT_ROOT/.build/release/blur"
PATTERNS=(bolt boxes circles target fire)

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

if [[ ! -f "$BLUR_BIN" ]]; then
    echo "Error: $BLUR_BIN not found. Build with: swift build -c release"
    exit 1
fi

echo "Running blur patterns (3 seconds each)..."
echo "Press Ctrl+C to stop"
echo ""

iteration=1
while true; do
    echo "=== Loop $iteration ==="
    for pattern in "${PATTERNS[@]}"; do
        echo "▶ Pattern: $pattern"
        "$BLUR_BIN" -h "$HOST" -g "$GEOMETRY" -t $TIMEOUT_ARG -d 50 "$pattern"
        echo ""
    done
    ((iteration++))
done
