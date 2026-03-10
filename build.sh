#!/bin/zsh

# build.sh - Build script for FlaschenTaschenDemos

set -e

SCRIPT_DIR="$(cd "$(dirname "${ARGV0:A}")" && pwd)"
BUILD_DIR="$SCRIPT_DIR/.build"

usage() {
    echo "Usage: build.sh <action>"
    echo ""
    echo "Actions:"
    echo "  clean    Remove build artifacts"
    echo "  build    Build with debug symbols (default)"
    echo "  release  Build optimized release binary"
    exit 1
}

if [[ $# -eq 0 ]]; then
    usage
fi

action="$1"

case "$action" in
    clean)
        echo "🧹 Cleaning build directory..."
        rm -rf "$BUILD_DIR"
        echo "✓ Clean complete"
        ;;

    build)
        echo "🔨 Building (debug)..."
        swift build
        echo "✓ Build complete"
        echo "  Binaries: $BUILD_DIR/debug/"
        ;;

    release)
        echo "🚀 Building (release)..."
        swift build -c release
        echo "✓ Release build complete"
        echo "  Binaries: $BUILD_DIR/release/"
        ;;

    *)
        echo "Error: Unknown action '$action'"
        usage
        ;;
esac
