#!/bin/bash
# pixelflow launcher — opens index.html in Chrome's app window (no browser chrome).
# Falls back to Safari and finally to the default browser.

set -e

DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
URL="file://$DIR/index.html"

if [ -d "/Applications/Google Chrome.app" ]; then
    open -na "Google Chrome" --args --app="$URL" --start-fullscreen
elif [ -d "/Applications/Microsoft Edge.app" ]; then
    open -na "Microsoft Edge" --args --app="$URL" --start-fullscreen
elif [ -d "/Applications/Safari.app" ]; then
    open -a "Safari" "$URL"
else
    open "$URL"
fi
