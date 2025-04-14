#!/bin/zsh

# Set main paths
BASE_DIR=~/Documents/esradev/cli-tools/whisper-recorder
RECORDINGS_DIR="$BASE_DIR/recordings"
TRANSCRIPT_FILE="$BASE_DIR/transcripts/full_transcription.txt"

# Make sure folders exist
mkdir -p "$RECORDINGS_DIR"
mkdir -p "$(dirname "$TRANSCRIPT_FILE")"

# Generate unique recording name
TIMESTAMP=$(date +%Y%m%d_%H%M%S)
AUDIO_FILE="$RECORDINGS_DIR/recording_$TIMESTAMP.wav"

# Start recording
echo "🎤 Recording... (press any key to stop)"
rec -q "$AUDIO_FILE" &
REC_PID=$!

# Wait for any keypress to stop
read -k1
kill $REC_PID
wait $REC_PID 2>/dev/null

# Downsample to 16kHz mono PCM for Whisper
sox "$AUDIO_FILE" -r 16000 -c 1 "$AUDIO_FILE.tmp.wav"
mv "$AUDIO_FILE.tmp.wav" "$AUDIO_FILE"

# Activate venv
source ~/whisper-env/bin/activate

# Transcribe and read content
echo "🧠 Transcribing..."
PYTHONWARNINGS="ignore" whisper "$AUDIO_FILE" --language English --model base.en --output_format txt --output_dir "$RECORDINGS_DIR"

TRANSCRIPTION_FILE="$RECORDINGS_DIR/recording_$TIMESTAMP.txt"
TRANSCRIBED_TEXT=$(cat "$TRANSCRIPTION_FILE")

# Append to global transcription log
echo "\n--- $TIMESTAMP ---\n$TRANSCRIBED_TEXT\n" >> "$TRANSCRIPT_FILE"

# Copy to clipboard (ClipCut compatible)
echo "$TRANSCRIBED_TEXT" | pbcopy

# Reopen fresh version in TextEdit
osascript -e 'tell application "TextEdit" to close every document whose path ends with "full_transcription.txt"' 2>/dev/null
open -a TextEdit "$TRANSCRIPT_FILE"

echo "✅ Done! Text copied to clipboard. Saved at:"
echo "$TRANSCRIPT_FILE"

