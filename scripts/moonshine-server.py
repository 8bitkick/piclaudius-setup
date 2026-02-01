#!/usr/bin/env python3
"""
Moonshine transcription server using quantized ONNX models.
Based on 8bitkick's fast implementation.
"""
import os
import sys
import socket
import json
import numpy as np
import soundfile as sf

# Add scripts dir to path for moonshine_fast
sys.path.insert(0, os.path.dirname(__file__))
from moonshine_fast import SpeechToText

SOCKET_PATH = "/tmp/moonshine.sock"
MODEL = "base"  # base is more accurate, still fast with quantized

def main():
    # Remove old socket
    if os.path.exists(SOCKET_PATH):
        os.remove(SOCKET_PATH)
    
    # Load model (includes warmup transcription)
    print(f"Loading Moonshine {MODEL} (quantized)...", flush=True)
    stt = SpeechToText(model=MODEL)
    print("Model loaded! Listening on", SOCKET_PATH, flush=True)
    
    # Create socket
    server = socket.socket(socket.AF_UNIX, socket.SOCK_STREAM)
    server.bind(SOCKET_PATH)
    os.chmod(SOCKET_PATH, 0o666)
    server.listen(1)
    
    while True:
        conn, _ = server.accept()
        try:
            data = conn.recv(4096).decode('utf-8').strip()
            if not data:
                continue
            
            if not os.path.exists(data):
                conn.sendall(json.dumps({"error": f"File not found: {data}"}).encode())
                continue
            
            # Load audio
            audio, sr = sf.read(data, dtype="float32")
            
            # Transcribe
            text = stt.transcribe(audio)
            conn.sendall(json.dumps({"text": text}).encode())
        except Exception as e:
            conn.sendall(json.dumps({"error": str(e)}).encode())
        finally:
            conn.close()

if __name__ == "__main__":
    main()
