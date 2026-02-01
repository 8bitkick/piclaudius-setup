#!/bin/bash
# Fast Moonshine transcription client - talks to the server
# Usage: moonshine-client.sh <audio_file>

SOCKET="/tmp/moonshine.sock"

if [ ! -S "$SOCKET" ]; then
    echo "Error: Moonshine server not running (no socket at $SOCKET)" >&2
    exit 1
fi

# Convert to 16kHz WAV if needed (Discord sends OGG/Opus)
INPUT="$1"
if [[ "$INPUT" == *.ogg ]] || [[ "$INPUT" == *.opus ]]; then
    TMPWAV=$(mktemp /tmp/moonshine_XXXXXX.wav)
    ffmpeg -i "$INPUT" -ar 16000 -ac 1 "$TMPWAV" -y 2>/dev/null
    INPUT="$TMPWAV"
    trap "rm -f $TMPWAV" EXIT
fi

# Send path, get JSON response, extract text
echo "$INPUT" | nc -U "$SOCKET" | python3 -c "import sys,json; d=json.load(sys.stdin); print(d.get('text','') or d.get('error',''))"
