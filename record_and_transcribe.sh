#!/bin/bash

# 🎙️ Esra Whisper Recorder (Minimal version)
# One-shot voice-to-text: record → transcribe → copy → done
# No loops, no folders, just the transcript. 
# Run this from within your whisper-env virtualenv.

# Create temp folder
TMP_DIR="./tmp"
mkdir -p "$TMP_DIR"

# Timestamped output
timestamp=$(date +"%Y%m%d_%H%M%S")
WAV_FILE="$TMP_DIR/recording_$timestamp.wav"

echo ""
echo "🎤 Press ENTER to start recording..."
read -r
echo "🔴 Recording... Press ENTER to stop."
rec -q -c 1 -b 16 "$WAV_FILE" &
rec_pid=$!
read -r
kill "$rec_pid" >/dev/null 2>&1
wait "$rec_pid" 2>/dev/null
echo "🛑 Recording stopped. Transcribing..."

# Transcribe using whisper CLI (requires whisper installed in virtualenv)
echo "⏳ Transcribing (this may take ~5s)..."
TRANSCRIPT=$(~/whisper-env/bin/whisper "$WAV_FILE" --model small --language en --fp16 False --output_dir "$TMP_DIR")

# Use direct output for clipboard & display
TRANSCRIPT_TEXT=$(tail -n +1 "${TMP_DIR}/$(basename "$WAV_FILE" .wav).txt" | grep -vE '^\[')

echo ""
echo "📋 Transcript:"
echo "$TRANSCRIPT_TEXT"
echo "$TRANSCRIPT_TEXT" | pbcopy
echo "✅ Transcription done. Copied to clipboard."

