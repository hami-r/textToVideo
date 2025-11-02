#!/bin/bash
# Create modern karaoke-style narration video with word-by-word highlighting

AUDIO_FILE="${1}"
FORMAT="${2:-reels}"
SRT_FILE="${3}"
BG_COLOR="${4:-#1a1a2e}"

if [ -z "$AUDIO_FILE" ]; then
    echo "Usage: bash scripts/create-modern-video.sh <audio_file> [format] [srt_file] [bg_color]"
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
        FONTSIZE=48
        MARGINV=400
        BOX_HEIGHT=300
        Y_POS="(h-${BOX_HEIGHT})/2"
        FORMAT_NAME="Instagram Reels/TikTok"
        ;;
    youtube)
        WIDTH=1920
        HEIGHT=1080
        FONTSIZE=42
        MARGINV=150
        BOX_HEIGHT=200
        Y_POS="h-${MARGINV}-${BOX_HEIGHT}"
        FORMAT_NAME="YouTube"
        ;;
    facebook)
        WIDTH=1080
        HEIGHT=1080
        FONTSIZE=40
        MARGINV=200
        BOX_HEIGHT=250
        Y_POS="(h-${BOX_HEIGHT})/2"
        FORMAT_NAME="Facebook Feed"
        ;;
    *)
        echo "❌ Unknown format: $FORMAT"
        echo "Available formats: reels, story, tiktok, youtube, facebook"
        exit 1
        ;;
esac

BASENAME=$(basename "$AUDIO_FILE" | sed 's/\.[^.]*$//')
OUTPUT_FILE="output/${BASENAME}-${FORMAT}-modern.mp4"

echo "🎬 Creating modern $FORMAT_NAME video..."
echo "📐 Resolution: ${WIDTH}x${HEIGHT}"
echo "🎵 Audio: $AUDIO_FILE"
echo "📝 Subtitles: $SRT_FILE"
echo "🎥 Output: $OUTPUT_FILE"

# Get audio duration
DURATION=$(ffprobe -v error -show_entries format=duration -of default=noprint_wrappers=1:nokey=1 "$AUDIO_FILE")

# Get absolute path for SRT file (required by ffmpeg subtitles filter)
ABS_SRT_FILE="/workspace/$SRT_FILE"

if [ ! -f "$ABS_SRT_FILE" ]; then
    echo "❌ SRT file not found: $ABS_SRT_FILE"
    exit 1
fi

# Modern subtitle style with:
# - Large, bold text
# - Semi-transparent background box
# - Better positioning for vertical videos
# - Drop shadow for readability
# - Yellow highlight color for emphasis

SUBTITLE_STYLE="FontName=Arial Bold,FontSize=${FONTSIZE},PrimaryColour=&HFFFFFF&,SecondaryColour=&HFFFF00&,OutlineColour=&H000000&,BackColour=&H80000000&,Bold=1,Italic=0,BorderStyle=4,Outline=3,Shadow=2,MarginV=${MARGINV},MarginL=60,MarginR=60,Alignment=2"

# Create video with modern subtitle styling
ffmpeg -y \
  -f lavfi -i color=c=$BG_COLOR:s=${WIDTH}x${HEIGHT}:d=$DURATION:r=30 \
  -i "$AUDIO_FILE" \
  -vf "subtitles=${ABS_SRT_FILE}:force_style='${SUBTITLE_STYLE}'" \
  -c:v libx264 -preset medium -crf 23 \
  -c:a aac -b:a 192k \
  -map 0:v:0 -map 1:a:0 \
  -shortest \
  "$OUTPUT_FILE"

if [ $? -eq 0 ]; then
    echo "✅ Modern video created successfully!"
    echo "📹 Output: $OUTPUT_FILE"
    echo "📐 Resolution: ${WIDTH}x${HEIGHT}"
    echo "✨ Features: Large text, background box, better positioning"
else
    echo "❌ Video creation failed"
    exit 1
fi