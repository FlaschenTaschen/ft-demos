#!/bin/zsh

# firefly.sh - Runs each firefly pattern for 3 seconds with 10 fireflies

set -e

SCRIPT_DIR="$(cd "$(dirname "${(%):-%x}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"
FIREFLY_BIN="$PROJECT_ROOT/.build/release/firefly"
LIGHTS=10
PATTERNS=(firefly rainbow wave bounce twinkle pulse chase matrix)

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

if [[ ! -f "$FIREFLY_BIN" ]]; then
    echo "Error: $FIREFLY_BIN not found. Build with: swift build -c release"
    exit 1
fi

echo "Running firefly patterns (3 seconds each, 10 lights)..."
echo "Press Ctrl+C to stop"
echo ""

iteration=1
while true; do
    echo "=== Loop $iteration ==="
    for pattern in "${PATTERNS[@]}"; do
        echo "▶ Pattern: $pattern"
        "$FIREFLY_BIN" -h "$HOST" -g "$GEOMETRY" -t $TIMEOUT_ARG -p "$pattern" -n $LIGHTS
        echo ""
    done
    ((iteration++))
done
