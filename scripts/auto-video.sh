#!/usr/bin/env bash
# =====================================
# 🪄 Auto Video Generator (Karaoke Version)
# Uses your video-lib.sh to transcribe and create a karaoke-style video.
# Supports: background image, format, logo, and auto naming.
# =====================================

LIB_FILE="$(dirname "$0")/video-lib.sh"
INPUT_FILE="$1"
FORMAT="${2:-youtube}"               # youtube, reels, square, etc.
BG_IMAGE="${3:-}"                    # optional background image path
LOGO_IMAGE="${4:-}"                  # optional logo image path

# --- Load library ---
if [ ! -f "$LIB_FILE" ]; then
    echo "❌ Library not found: $LIB_FILE"
    exit 1
fi
source "$LIB_FILE"

# --- Validate input ---
if [ -z "$INPUT_FILE" ]; then
    echo "Usage: $0 <audio_file> [format] [bg_image] [logo_image]"
    echo "Example: $0 input/audio.wav reels assets/bg.jpg assets/logo.png"
    exit 1
fi
check_file "$INPUT_FILE" "Audio file" || exit 1

# --- Prep filenames ---
BASENAME=$(get_basename "$INPUT_FILE")
mkdir -p output
JSON_FILE="output/${BASENAME}.json"
ASS_FILE="output/${BASENAME}.ass"
FINAL_VIDEO="output/${BASENAME}_${FORMAT}_karaoke.mp4" # More descriptive name

echo "🎧 Input audio: $INPUT_FILE"
echo "🎬 Format: $FORMAT"
[ -n "$BG_IMAGE" ] && echo "🖼️  Background: $BG_IMAGE"
[ -n "$LOGO_IMAGE" ] && echo "🔖 Logo: $LOGO_IMAGE"
echo

# --- Step 1: Transcribe to JSON ---
if [ ! -f "$JSON_FILE" ]; then
    transcribe_to_json "$INPUT_FILE" || exit 1
else
    echo "📄 Using existing transcription: $JSON_FILE"
fi

# --- (Step 2 is skipped: SRT not needed for Karaoke) ---
# if [ ! -f "output/${BASENAME}.srt" ]; then
#     transcribe_to_srt "$INPUT_FILE" || exit 1
# else
#     echo "📜 Using existing SRT: output/${BASENAME}.srt"
# fi

# --- Step 2: Get format dimensions ---
SETTINGS=$(get_format_settings "$FORMAT")
if [ "$SETTINGS" == "ERROR" ]; then
    echo "❌ Unknown format: $FORMAT. Use youtube, reels, square, etc."
    exit 1
fi
IFS=':' read -r width height _ <<< "$SETTINGS"
echo "📐 Using dimensions: ${width}x${height}"

# --- Step 3: Generate ASS (Karaoke style) with correct dimensions ---
if [ ! -f "$ASS_FILE" ]; then
    generate_karaoke_ass "$JSON_FILE" "$width" "$height" "$ASS_FILE" || exit 1
else
    echo "🎵 Using existing ASS: $ASS_FILE"
fi

# --- Step 4: Create Karaoke Video ---
# We now call create_karaoke_video with all the necessary parameters
create_karaoke_video \
    "$INPUT_FILE" \
    "$ASS_FILE" \
    "$FINAL_VIDEO" \
    "" \
    "$width" \
    "$height" \
    "" \
    "medium" \
    23 \
    30 \
    "$LOGO_IMAGE" \
    "top-right" \
    0.12 \
    "$BG_IMAGE" \
    "cover"

# --- Step 5: Done ---
if [ $? -eq 0 ]; then
    echo
    echo "✅ Done! Karaoke video ready at: $FINAL_VIDEO"
else
    echo "❌ Video creation failed"
    exit 1
fi