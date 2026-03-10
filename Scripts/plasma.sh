#!/bin/zsh

# plasma.sh - Runs plasma demo with different color palette variations

set -e

SCRIPT_DIR="$(cd "$(dirname "${(%):-%x}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"
PLASMA_BIN="$PROJECT_ROOT/.build/release/plasma"
PALETTES=(0 1 2 3 4 5 6 7 8)
PALETTE_NAMES=(Rainbow Nebula Fire Bluegreen RGB Magma Inferno Plasma Viridis)

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

if [[ ! -f "$PLASMA_BIN" ]]; then
    echo "Error: $PLASMA_BIN not found. Build with: swift build -c release"
    exit 1
fi

echo "Running plasma patterns (3 seconds each)..."
echo "Press Ctrl+C to stop"
echo ""

iteration=1
while true; do
    echo "=== Loop $iteration ==="
    for (( i = 1; i <= ${#PALETTES[@]}; i++ ))
    do
        palette="${PALETTES[$i]}"
        name="${PALETTE_NAMES[$i]}"
        echo "▶ Palette $palette: $name"
        "$PLASMA_BIN" -h "$HOST" -g "$GEOMETRY" -t $TIMEOUT_ARG -d 50 -p "$palette"
        echo ""
    done
    ((iteration++))
done
