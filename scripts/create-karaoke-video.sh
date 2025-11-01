#!/usr/bin/env bash
set -e

AUDIO_FILE="$1"
ASPECT="$2" # e.g. reels / square / landscape

if [ -z "$AUDIO_FILE" ] || [ -z "$ASPECT" ]; then
  echo "Usage: $0 <audio_file.wav> <aspect: reels|square|landscape>"
  exit 1
fi

# -------------------- CONFIG --------------------
OUTPUT_DIR="output"
mkdir -p "$OUTPUT_DIR"

JSON_FILE="$OUTPUT_DIR/audio.json"
ASS_FILE="$OUTPUT_DIR/audio-karaoke.ass"
VIDEO_FILE="$OUTPUT_DIR/audio-$ASPECT-karaoke.mp4"

# Default: Reels 1080x1920
case "$ASPECT" in
  reels)
    WIDTH=1080
    HEIGHT=1920
    ;;
  square)
    WIDTH=1080
    HEIGHT=1080
    ;;
  landscape)
    WIDTH=1920
    HEIGHT=1080
    ;;
  *)
    echo "❌ Unknown aspect ratio '$ASPECT'. Use reels|square|landscape"
    exit 1
    ;;
esac

BG_COLOR="black"

# -------------------- STEP 1: Generate subtitles --------------------
echo "🎵 Generating karaoke ASS subtitles..."

python3 - <<'PYTHON' "$JSON_FILE" "$WIDTH" "$HEIGHT" "$ASS_FILE"
import json, sys, os, re

json_file, width, height, output_ass = sys.argv[1:]
width, height = int(width), int(height)

def time_to_seconds(t):
    """Convert 'HH:MM:SS,ms' to seconds (float)."""
    try:
        h, m, rest = t.split(":")
        s, ms = rest.split(",")
        return int(h)*3600 + int(m)*60 + int(s) + int(ms)/1000
    except ValueError:
        print(f"⚠️ Invalid timestamp format: {t}")
        return 0


def format_time(seconds):
    """Convert seconds -> ASS timestamp (h:mm:ss.cc)."""
    hours = int(seconds // 3600)
    minutes = int((seconds % 3600) // 60)
    secs = int(seconds % 60)
    centisecs = int((seconds % 1) * 100)
    return f"{hours}:{minutes:02d}:{secs:02d}.{centisecs:02d}"

def generate_karaoke_ass(json_file, width, height, output_ass):
    if not os.path.exists(json_file):
        print(f"❌ JSON not found: {json_file}")
        return False

    with open(json_file, 'r') as f:
        data = json.load(f)

    segments = data.get("transcription", [])
    if not segments:
        print("❌ No transcription segments found.")
        return False

    is_vertical = height > width
    fontsize = 52 if is_vertical else (44 if width == height else 48)
    margin_v = 400 if is_vertical else (250 if width == height else 150)

    ass = f"""[Script Info]
Title: Karaoke Subtitles
ScriptType: v4.00+
WrapStyle: 0
PlayResX: {width}
PlayResY: {height}
ScaledBorderAndShadow: yes

[V4+ Styles]
Format: Name, Fontname, Fontsize, PrimaryColour, SecondaryColour, OutlineColour, BackColour, Bold, Italic, Underline, StrikeOut, ScaleX, ScaleY, Spacing, Angle, BorderStyle, Outline, Shadow, Alignment, MarginL, MarginR, MarginV, Encoding
Style: Default,Arial,{fontsize},&H00FFFFFF,&H00FFFFFF,&H00000000,&H80000000,-1,0,0,0,100,100,0,0,1,3,2,2,80,80,{margin_v},1
Style: Highlight,Arial,{fontsize},&H0000FFFF,&H0000FFFF,&H00000000,&H80000000,-1,0,0,0,100,100,0,0,1,3,2,2,80,80,{margin_v},1

[Events]
Format: Layer, Start, End, Style, Name, MarginL, MarginR, MarginV, Effect, Text
"""

    for seg in segments:
        ts = seg.get("timestamps", {})
        start = ts.get("from")
        end = ts.get("to")
        text = seg.get("text", "").strip()
        if not start or not end or not text:
            continue

        start_s = time_to_seconds(start)
        end_s = time_to_seconds(end)
        duration_cs = int((end_s - start_s) * 100)
        start_fmt = format_time(start_s)
        end_fmt = format_time(end_s)

        # Simple karaoke timing (whole line)
        ass += f"Dialogue: 0,{start_fmt},{end_fmt},Highlight,,0,0,0,,{{\\k{duration_cs}}}{text}\n"

    with open(output_ass, 'w') as f:
        f.write(ass)

    print(f"✅ Generated karaoke subtitles: {output_ass}")
    return True

if not generate_karaoke_ass(json_file, width, height, output_ass):
    sys.exit(1)
PYTHON


# -------------------- STEP 2: Create video --------------------
echo "🎬 Creating karaoke video..."
DURATION=$(ffprobe -v error -show_entries format=duration -of csv=p=0 "$AUDIO_FILE")
DURATION=${DURATION%.*}

ffmpeg -y \
  -f lavfi -i color=c=$BG_COLOR:s=${WIDTH}x${HEIGHT}:d=$DURATION:r=30 \
  -i "$AUDIO_FILE" \
  -vf "ass=$ASS_FILE:fontsdir=/usr/share/fonts/truetype/dejavu" \
  -c:v libx264 -preset medium -crf 23 \
  -c:a aac -b:a 192k \
  -shortest "$VIDEO_FILE"

echo "✅ Karaoke video created successfully!"
echo "📹 Output: $VIDEO_FILE"
