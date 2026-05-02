#!/bin/bash
# pixelflow overlay launcher — translucent always-on-top overlay across all screens.
# Compiles overlay.swift to a binary on first run (cached for speed) and launches
# it detached so this terminal window can be closed safely.

DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$DIR"

if ! command -v swiftc &> /dev/null; then
    osascript -e 'display dialog "pixelflow overlay needs the Swift toolchain. Install Xcode Command Line Tools by running this in Terminal:\n\n    xcode-select --install\n\nThen try again." buttons {"OK"} default button "OK" with title "pixelflow"'
    exit 1
fi

SOURCE="overlay.swift"
BINARY=".pixelflow-overlay"

# Recompile if missing or out of date
if [ ! -x "$BINARY" ] || [ "$SOURCE" -nt "$BINARY" ]; then
    echo "Compiling overlay..."
    if ! swiftc "$SOURCE" -o "$BINARY"; then
        echo "Build failed — see errors above."
        exit 1
    fi
fi

# Stop any existing instance so we don't pile up overlays.
# Match on the binary name only — ps shows it as "./.pixelflow-overlay" not the full path.
pkill -f "pixelflow-overlay" 2>/dev/null
sleep 0.4

# Launch detached, redirect logs so closing the terminal doesn't kill the app
nohup "./$BINARY" > /tmp/pixelflow-overlay.log 2>&1 &
disown

echo ""
echo "✦ pixelflow overlay running."
echo "  Click the menu-bar ✦ icon to pause, adjust, or quit."
echo "  This terminal window is safe to close."
echo ""
sleep 1
