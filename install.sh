#!/bin/bash
# PiClawdius v2 Setup Script
# Installs optimized skills, dependencies, and Moonshine server for OpenClaw on Raspberry Pi

set -e

echo "🦞 PiClawdius v2 Setup - Installing Optimized Skills & Dependencies"
echo ""

# Check if OpenClaw is installed
if ! command -v openclaw &> /dev/null; then
    echo "❌ OpenClaw not found. Please install OpenClaw first:"
    echo "   https://docs.openclaw.ai/installation"
    exit 1
fi

# Get workspace directory
WORKSPACE_DIR="${HOME}/.openclaw/workspace"
SKILLS_DIR="${WORKSPACE_DIR}/skills"
SCRIPTS_DIR="${WORKSPACE_DIR}/scripts"

echo "📂 Workspace: ${WORKSPACE_DIR}"
echo ""

# Create directories
mkdir -p "${SKILLS_DIR}" "${SCRIPTS_DIR}"

# Get script directory
SETUP_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )"

# Install skills
echo "📦 Installing skills..."

if [ -f "${SETUP_DIR}/skills/moonshine-stt.skill" ]; then
    echo "  Installing moonshine-stt..."
    openclaw skills install "${SETUP_DIR}/skills/moonshine-stt.skill"
else
    echo "  ⚠️  moonshine-stt.skill not found, skipping"
fi

if [ -f "${SETUP_DIR}/skills/supertonic-tts.skill" ]; then
    echo "  Installing supertonic-tts..."
    openclaw skills install "${SETUP_DIR}/skills/supertonic-tts.skill"
else
    echo "  ⚠️  supertonic-tts.skill not found, skipping"
fi

echo ""
echo "📚 Installing Python dependencies..."

# Install Moonshine STT dependencies
echo "  Installing Moonshine STT..."
pip install onnxruntime numpy soundfile huggingface-hub tokenizers --quiet

# Install Supertonic TTS
echo "  Installing Supertonic TTS..."
pip install git+https://github.com/8bitkick/supertonic-py.git --quiet

echo ""
echo "🔧 Setting up Moonshine server..."

# Copy server scripts to workspace
if [ -d "${SETUP_DIR}/scripts" ]; then
    echo "  Copying server scripts to ${SCRIPTS_DIR}..."
    cp "${SETUP_DIR}"/scripts/* "${SCRIPTS_DIR}/"
    chmod +x "${SCRIPTS_DIR}"/moonshine-client.sh 2>/dev/null || true
else
    echo "  ⚠️  scripts/ directory not found, skipping server setup"
fi

echo ""
echo "⚙️  Configuring OpenClaw..."

# Update OpenClaw config to use the fast client
CONFIG_FILE="${HOME}/.openclaw/openclaw.json"
if [ -f "$CONFIG_FILE" ]; then
    echo "  Updating config to use moonshine-client.sh (server-based, 9x faster)..."
    
    # Backup config
    cp "$CONFIG_FILE" "${CONFIG_FILE}.backup.$(date +%s)"
    
    # Use Python to update the config
    python3 << 'EOF'
import json
import os

config_file = os.path.expanduser("~/.openclaw/openclaw.json")
with open(config_file, 'r') as f:
    config = json.load(f)

# Update the audio transcription command
if 'tools' not in config:
    config['tools'] = {}
if 'media' not in config['tools']:
    config['tools']['media'] = {}
if 'audio' not in config['tools']['media']:
    config['tools']['media']['audio'] = {'enabled': True, 'models': [{}]}

# Set the command
models = config['tools']['media']['audio'].get('models', [{}])
if len(models) == 0:
    models = [{}]
    
scripts_dir = os.path.expanduser("~/.openclaw/workspace/scripts")
models[0]['command'] = f"{scripts_dir}/moonshine-client.sh"
config['tools']['media']['audio']['models'] = models

with open(config_file, 'w') as f:
    json.dump(config, f, indent=2)

print("  ✅ Config updated")
EOF
else
    echo "  ⚠️  Config file not found at $CONFIG_FILE"
fi

echo ""
echo "🚀 Starting Moonshine server..."

# Check if server is already running
if [ -S /tmp/moonshine.sock ]; then
    echo "  ℹ️  Server already running at /tmp/moonshine.sock"
else
    # Start server in background
    cd "${SCRIPTS_DIR}"
    nohup python3 moonshine-server.py > /tmp/moonshine-server.log 2>&1 &
    SERVER_PID=$!
    
    # Wait for socket to appear
    for i in {1..10}; do
        if [ -S /tmp/moonshine.sock ]; then
            echo "  ✅ Server started (PID: $SERVER_PID)"
            break
        fi
        sleep 0.5
    done
    
    if [ ! -S /tmp/moonshine.sock ]; then
        echo "  ⚠️  Server may have failed to start. Check /tmp/moonshine-server.log"
    fi
fi

echo ""
echo "📝 To install Moonshine as a systemd service (auto-start on boot):"
echo "   sudo cp ${SETUP_DIR}/scripts/moonshine.service /etc/systemd/system/"
echo "   sudo systemctl enable moonshine"
echo "   sudo systemctl start moonshine"
echo ""

echo "🔄 Restarting OpenClaw..."
openclaw gateway restart || echo "  ⚠️  Could not restart OpenClaw automatically. Please restart manually."

echo ""
echo "✅ Installation complete!"
echo ""
echo "Next steps:"
echo "  1. Wait for OpenClaw to restart (~10 seconds)"
echo "  2. Test with a voice message in Discord!"
echo "  3. Optionally install Moonshine as a systemd service (see above)"
echo ""
echo "Performance:"
echo "  - STT: ~0.26s for voice messages (9x faster!)"
echo "  - TTS: 2-3x realtime on Pi 5"
echo ""
echo "Created by PiClawdius 🦞"
