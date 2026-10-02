#!/bin/bash
# 🎙️ Esra Whisper Recorder: record, transcribe offline with Whisper, copy the text to the clipboard (macOS).
#
# Usage: ./record_and_transcribe.sh [--keep] [audio-file]
#   audio-file  transcribe this file instead of recording
#   --keep      keep the recording and transcript (the folder is printed)
#
# Settings (environment variables):
#   WHISPER_BIN    path to the whisper CLI (default: whisper on PATH, else ~/whisper-env/bin/whisper)
#   WHISPER_MODEL  tiny, base, small, medium, large (default: small)
#   WHISPER_LANG   language code such as en, de, tr (default: Whisper detects the language)

set -euo pipefail

WHISPER_BIN="${WHISPER_BIN:-$(command -v whisper || echo "$HOME/whisper-env/bin/whisper")}"
WHISPER_MODEL="${WHISPER_MODEL:-small}"
WHISPER_LANG="${WHISPER_LANG:-}"
SAMPLE_RATE_HZ=16000

fail() {
  echo "❌ $1" >&2
  exit 1
}

keep_files=false
input_file=""
for argument in "$@"; do
  case "$argument" in
    --keep) keep_files=true ;;
    -h | --help)
      sed -n '2,12p' "$0" | sed 's/^# \{0,1\}//'
      exit 0
      ;;
    -*) fail "Unknown option: $argument (see --help)" ;;
    *) input_file="$argument" ;;
  esac
done

command -v pbcopy >/dev/null || fail "pbcopy not found. This script is for macOS."
[[ -x "$WHISPER_BIN" ]] || fail "Whisper not found at $WHISPER_BIN. Set WHISPER_BIN or follow the README setup."
if [[ -z "$input_file" ]]; then
  command -v rec >/dev/null || fail "rec not found. Install SoX: brew install sox"
fi

work_dir="$(mktemp -d)"
recorder_pid=""
cleanup() {
  # Ctrl-C does not reach a background job in a script, so stop the recorder explicitly.
  if [[ -n "$recorder_pid" ]]; then kill "$recorder_pid" 2>/dev/null || true; fi
  if ! $keep_files; then rm -rf "$work_dir"; fi
}
trap cleanup EXIT
trap 'exit 130' INT
trap 'exit 143' TERM
if $keep_files; then
  echo "📁 Files are kept in $work_dir"
fi

if [[ -n "$input_file" ]]; then
  [[ -f "$input_file" ]] || fail "No such file: $input_file"
  audio_file="$input_file"
else
  audio_file="$work_dir/recording.wav"
  echo ""
  echo "🎤 Press ENTER to start recording..."
  read -r
  echo "🔴 Recording... Press ENTER to stop."
  rec -q -V1 -r "$SAMPLE_RATE_HZ" -c 1 -b 16 "$audio_file" &
  recorder_pid=$!
  read -r
  kill "$recorder_pid" 2>/dev/null || true
  wait "$recorder_pid" 2>/dev/null || true
  recorder_pid=""
  echo "🛑 Recording stopped."
fi

echo "⏳ Transcribing with the '$WHISPER_MODEL' model..."
language_option=()
if [[ -n "$WHISPER_LANG" ]]; then
  language_option=(--language "$WHISPER_LANG")
fi
# --fp16 False: the reference Whisper runs on the CPU on Macs, where fp16 is unsupported and only warns.
"$WHISPER_BIN" "$audio_file" --model "$WHISPER_MODEL" ${language_option[@]+"${language_option[@]}"} \
  --fp16 False --output_format txt --output_dir "$work_dir" >/dev/null ||
  fail "Whisper failed (see the error above). Your clipboard was not changed."

audio_name="$(basename "$audio_file")"
transcript_file="$work_dir/${audio_name%.*}.txt"
[[ -s "$transcript_file" ]] || fail "Whisper produced no text. Your clipboard was not changed."
transcript="$(<"$transcript_file")"
[[ -n "${transcript//[[:space:]]/}" ]] || fail "Whisper produced no text. Your clipboard was not changed."

echo ""
echo "📋 Transcript:"
echo "$transcript"
printf '%s' "$transcript" | pbcopy
echo "✅ Copied to clipboard."
