#!/bin/bash
# Create narration video from audio and SRT subtitles

AUDIO_FILE="${1:-input/audio.wav}"
SRT_FILE="${2}"
OUTPUT_FILE="${3:-output/narration-video.mp4}"
BG_COLOR="${4:-#1a1a2e}"

# Auto-detect SRT file if not provided
if [ -z "$SRT_FILE" ]; then
    BASENAME=$(basename "$AUDIO_FILE" | sed 's/\.[^.]*$//')
    SRT_FILE="output/${BASENAME}.srt"
fi

if [ ! -f "$AUDIO_FILE" ]; then
    echo "❌ Audio file not found: $AUDIO_FILE"
    exit 1
fi

if [ ! -f "$SRT_FILE" ]; then
    echo "❌ SRT file not found: $SRT_FILE"
    echo "💡 Run transcription first: bash scripts/transcribe.sh"
    exit 1
fi

echo "🎬 Creating narration video..."
echo "🎵 Audio: $AUDIO_FILE"
echo "📝 Subtitles: $SRT_FILE"
echo "🎥 Output: $OUTPUT_FILE"

# Get audio duration
DURATION=$(ffprobe -v error -show_entries format=duration -of default=noprint_wrappers=1:nokey=1 "$AUDIO_FILE")

# Create video with solid background and burned-in subtitles
ffmpeg -y \
  -f lavfi -i color=c=$BG_COLOR:s=1920x1080:d=$DURATION:r=30 \
  -i "$AUDIO_FILE" \
  -vf "subtitles=$SRT_FILE:force_style='FontName=Arial,FontSize=24,PrimaryColour=&HFFFFFF,OutlineColour=&H000000,BorderStyle=3,Outline=2,Shadow=0,MarginV=50,Alignment=2'" \
  -c:v libx264 -preset medium -crf 23 \
  -c:a aac -b:a 192k \
  -map 0:v:0 -map 1:a:0 \
  -shortest \
  "$OUTPUT_FILE"

if [ $? -eq 0 ]; then
    echo "✅ Video created successfully!"
    echo "📹 Output: $OUTPUT_FILE"
else
    echo "❌ Video creation failed"
    exit 1
fi