#!/bin/bash
# Create narration video for different social media platforms

AUDIO_FILE="${1}"
FORMAT="${2:-reels}"  # reels, youtube, facebook, tiktok, story
SRT_FILE="${3}"
BG_COLOR="${4:-#1a1a2e}"

if [ -z "$AUDIO_FILE" ]; then
    echo "Usage: bash scripts/create-social-video.sh <audio_file> [format] [srt_file] [bg_color]"
    echo ""
    echo "Formats:"
    echo "  reels     - Instagram Reels/TikTok (1080x1920, 9:16)"
    echo "  story     - Instagram/Facebook Story (1080x1920, 9:16)"
    echo "  youtube   - YouTube (1920x1080, 16:9)"
    echo "  facebook  - Facebook Feed (1080x1080, 1:1)"
    echo "  tiktok    - TikTok (1080x1920, 9:16)"
    exit 1
fi

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

# Set dimensions and subtitle style based on format
case "$FORMAT" in
    reels|story|tiktok)
        WIDTH=1080
        HEIGHT=1920
        FONTSIZE=32
        MARGINV=100
        FORMAT_NAME="Instagram Reels/TikTok"
        ;;
    youtube)
        WIDTH=1920
        HEIGHT=1080
        FONTSIZE=28
        MARGINV=60
        FORMAT_NAME="YouTube"
        ;;
    facebook)
        WIDTH=1080
        HEIGHT=1080
        FONTSIZE=30
        MARGINV=80
        FORMAT_NAME="Facebook Feed"
        ;;
    *)
        echo "❌ Unknown format: $FORMAT"
        echo "Available formats: reels, story, tiktok, youtube, facebook"
        exit 1
        ;;
esac

BASENAME=$(basename "$AUDIO_FILE" | sed 's/\.[^.]*$//')
OUTPUT_FILE="output/${BASENAME}-${FORMAT}.mp4"

echo "🎬 Creating $FORMAT_NAME video..."
echo "📐 Resolution: ${WIDTH}x${HEIGHT}"
echo "🎵 Audio: $AUDIO_FILE"
echo "📝 Subtitles: $SRT_FILE"
echo "🎥 Output: $OUTPUT_FILE"

# Get audio duration
DURATION=$(ffprobe -v error -show_entries format=duration -of default=noprint_wrappers=1:nokey=1 "$AUDIO_FILE")

# Create video with format-specific dimensions
ffmpeg -y \
  -f lavfi -i color=c=$BG_COLOR:s=${WIDTH}x${HEIGHT}:d=$DURATION:r=30 \
  -i "$AUDIO_FILE" \
  -vf "subtitles=$SRT_FILE:force_style='FontName=Arial,FontSize=${FONTSIZE},PrimaryColour=&HFFFFFF,OutlineColour=&H000000,BorderStyle=3,Outline=2,Shadow=0,MarginV=${MARGINV},Alignment=2'" \
  -c:v libx264 -preset medium -crf 23 \
  -c:a aac -b:a 192k \
  -map 0:v:0 -map 1:a:0 \
  -shortest \
  "$OUTPUT_FILE"

if [ $? -eq 0 ]; then
    echo "✅ Video created successfully!"
    echo "📹 Output: $OUTPUT_FILE"
    echo "📐 Resolution: ${WIDTH}x${HEIGHT}"
else
    echo "❌ Video creation failed"
    exit 1
fi