#!/bin/bash
# Fast Moonshine transcription client - talks to the server
# Usage: moonshine-client.sh <audio_file>

SOCKET="/tmp/moonshine.sock"

if [ ! -S "$SOCKET" ]; then
    echo "Error: Moonshine server not running (no socket at $SOCKET)" >&2
    exit 1
fi

# Send path, get JSON response, extract text
echo "$1" | nc -U "$SOCKET" | python3 -c "import sys,json; d=json.load(sys.stdin); print(d.get('text','') or d.get('error',''))"
