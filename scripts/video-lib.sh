#!/usr/bin/env bash
# Video Creation Library - Modular functions for audio transcription and video generation
# VERSION 3.0 - Combined & Complete with all Image Features

# ==================== CONFIGURATION ====================
# These can be overridden by setting environment variables before sourcing
DEFAULT_MODEL="${WHISPER_MODEL:-/opt/whisper.cpp/models/ggml-base.en.bin}"
OUTPUT_DIR="${VIDEO_OUTPUT_DIR:-output}"
WHISPER_CLI="${WHISPER_CLI_PATH:-/opt/whisper.cpp/build/bin/whisper-cli}"
DEFAULT_FONT="${VIDEO_FONT:-Arial}"
DEFAULT_FONT_DIR="${VIDEO_FONT_DIR:-/usr/share/fonts/truetype/dejavu}"

# ==================== UTILITY FUNCTIONS ====================

# Get basename without extension
get_basename() {
    local file="$1"
    basename "$file" | sed 's/\.[^.]*$//'
}

# Check if file exists
check_file() {
    local file="$1"
    local description="${2:-File}"
    if [ ! -f "$file" ]; then
        echo "❌ $description not found: $file" >&2
        return 1
    fi
    return 0
}

# Get audio duration in seconds
get_audio_duration() {
    local audio_file="$1"
    ffprobe -v error -show_entries format=duration \
        -of default=noprint_wrappers=1:nokey=1 "$audio_file"
}

# Get video dimensions and settings based on format
get_format_settings() {
    local format="$1"
    case "$format" in
        reels|story|tiktok)
            echo "1080:1920:48:400:300"  # width:height:fontsize:marginv:box_height
            ;;
        youtube)
            echo "1920:1080:42:150:200"
            ;;
        facebook|square)
            echo "1080:1080:40:200:250"
            ;;
        landscape)
            echo "1920:1080:48:150:200"
            ;;
        *)
            echo "ERROR" >&2
            return 1
            ;;
    esac
}

# ==================== TRANSCRIPTION FUNCTIONS ====================

# Transcribe audio file to JSON
transcribe_to_json() {
    local audio_file="$1"
    local model="${2:-$DEFAULT_MODEL}"
    local output_dir="${3:-$OUTPUT_DIR}"
    
    check_file "$audio_file" "Audio file" || return 1
    check_file "$model" "Model" || return 1
    
    mkdir -p "$output_dir"
    
    local basename=$(get_basename "$audio_file")
    local json_file="$output_dir/${basename}.json"
    
    if [ -f "$json_file" ]; then
        echo "📄 Found existing transcription: $json_file"
        echo "$json_file"
        return 0
    fi
    
    echo "🎙️ Transcribing audio using Whisper..."
    "$WHISPER_CLI" -m "$model" -f "$audio_file" -oj -of "$output_dir/$basename"
    
    if [ $? -eq 0 ]; then
        echo "✅ Transcription complete: $json_file"
        echo "$json_file"
        return 0
    else
        echo "❌ Transcription failed" >&2
        return 1
    fi
}

# Transcribe audio file to SRT
transcribe_to_srt() {
    local audio_file="$1"
    local model="${2:-$DEFAULT_MODEL}"
    local output_dir="${3:-$OUTPUT_DIR}"
    
    check_file "$audio_file" "Audio file" || return 1
    check_file "$model" "Model" || return 1
    
    mkdir -p "$output_dir"
    
    local basename=$(get_basename "$audio_file")
    local srt_file="$output_dir/${basename}.srt"
    
    if [ -f "$srt_file" ]; then
        echo "📄 Found existing SRT: $srt_file"
        echo "$srt_file"
        return 0
    fi
    
    echo "🎙️ Transcribing audio to SRT..."
    "$WHISPER_CLI" -m "$model" -f "$audio_file" -osrt -of "$output_dir/$basename"
    
    if [ $? -eq 0 ]; then
        echo "✅ Transcription complete: $srt_file"
        echo "$srt_file"
        return 0
    else
        echo "❌ Transcription failed" >&2
        return 1
    fi
}

# ==================== SUBTITLE GENERATION FUNCTIONS ====================

# Generate ASS karaoke subtitles from JSON
generate_karaoke_ass() {
    local json_file="$1"
    local width="$2"
    local height="$3"
    local output_ass="$4"
    
    check_file "$json_file" "JSON file" || return 1
    
    echo "🎵 Generating karaoke ASS subtitles..."
    
    python3 - "$json_file" "$width" "$height" "$output_ass" <<'PYTHON'
import json, sys, os

def time_to_seconds(t):
    try:
        if isinstance(t, (int, float)):
            return float(t)
        h, m, rest = t.split(":")
        s, ms = rest.split(",")
        return int(h)*3600 + int(m)*60 + int(s) + int(ms)/1000
    except (ValueError, AttributeError):
        return 0

def format_time(seconds):
    hours = int(seconds // 3600)
    minutes = int((seconds % 3600) // 60)
    secs = int(seconds % 60)
    centisecs = int((seconds % 1) * 100)
    return f"{hours}:{minutes:02d}:{secs:02d}.{centisecs:02d}"

json_file, width, height, output_ass = sys.argv[1:]
width, height = int(width), int(height)

with open(json_file, 'r') as f:
    data = json.load(f)

segments = data.get("transcription") or data.get("segments") or []
if not segments:
    print("❌ No transcription segments found.")
    sys.exit(1)

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
    ts = seg.get("timestamps") or {}
    start = ts.get("from") or seg.get("start")
    end = ts.get("to") or seg.get("end")
    text = seg.get("text", "").strip()
    if not start or not end or not text:
        continue
    
    start_s = time_to_seconds(start)
    end_s = time_to_seconds(end)
    duration_cs = int((end_s - start_s) * 100)
    start_fmt = format_time(start_s)
    end_fmt = format_time(end_s)
    
    ass += f"Dialogue: 0,{start_fmt},{end_fmt},Highlight,,0,0,0,,{{\\k{duration_cs}}}{text}\n"

with open(output_ass, 'w') as f:
    f.write(ass)

print(f"✅ Generated karaoke subtitles: {output_ass}")
PYTHON
    
    if [ $? -eq 0 ]; then
        echo "$output_ass"
        return 0
    else
        echo "❌ ASS generation failed" >&2
        return 1
    fi
}

# ==================== IMAGE HANDLING FUNCTIONS ====================

# Create video filter for a background image with different modes
create_background_filter() {
    local mode="${1:-scale}" # scale, cover, contain
    local width="$2"
    local height="$3"

    case "$mode" in
        cover)
            # Scale to cover, maintain aspect ratio, and crop
            echo "scale=w='if(gte(iw/ih,${width}/${height}),-1,${width})':h='if(gte(iw/ih,${width}/${height}),${height},-1)',crop=${width}:${height}"
            ;;
        contain)
            # Scale to fit, maintain aspect ratio, and pad with black bars
            echo "scale=w='if(gt(a,${width}/${height}),${width},-1)':h='if(gt(a,${width}/${height}),-1,${height})',pad=${width}:${height}:(ow-iw)/2:(oh-ih)/2:color=black"
            ;;
        scale|*)
            # Default: stretch to fill dimensions
            echo "scale=${width}:${height}"
            ;;
    esac
}

# Create video filter string for an image overlay
create_overlay_filter_string() {
    local position="${1:-top-right}"
    local scale="${2:-0.15}"
    local opacity="${3:-1.0}"
    
    # Calculate position based on preset
    local x_pos y_pos
    case "$position" in
        center) x_pos="(W-w)/2"; y_pos="(H-h)/2" ;;
        top-left) x_pos="50"; y_pos="50" ;;
        top-right) x_pos="W-w-50"; y_pos="50" ;;
        bottom-left) x_pos="50"; y_pos="H-h-50" ;;
        bottom-right) x_pos="W-w-50"; y_pos="H-h-50" ;;
        top-center) x_pos="(W-w)/2"; y_pos="50" ;;
        bottom-center) x_pos="(W-w)/2"; y_pos="H-h-50" ;;
        *) echo "❌ Unknown position: $position" >&2; return 1 ;;
    esac
    
    # Returns a generic filter chain segment.
    # Expects input streams to be named [base] for the video and [img] for the overlay.
    echo "[img]scale=iw*${scale}:-1,format=rgba,colorchannelmixer=aa=${opacity}[overlay];[base][overlay]overlay=${x_pos}:${y_pos}"
}

# Add single logo/watermark to existing video
add_logo_to_video() {
    local input_video="$1"
    local image_file="$2"
    local output_video="$3"
    local position="${4:-top-right}"
    local scale="${5:-0.15}"
    local opacity="${6:-1.0}"
    
    check_file "$input_video" "Input video" || return 1
    check_file "$image_file" "Image file" || return 1
    
    echo "🖼️  Adding logo to video..."
    
    local filter_str=$(create_overlay_filter_string "$position" "$scale" "$opacity")
    # Adapt the generic filter string for a simple 2-input command
    local filter_complex="${filter_str/\[base\]/[0:v]}"
    filter_complex="${filter_complex/\[img\]/[1:v]}"

    ffmpeg -y -i "$input_video" -i "$image_file" \
        -filter_complex "$filter_complex" \
        -c:v libx264 -preset medium -crf 23 \
        -c:a copy \
        "$output_video"
    
    if [ $? -eq 0 ]; then
        echo "✅ Logo added: $output_video"; return 0;
    else
        echo "❌ Failed to add logo"; return 1;
    fi
}

# Resize/prepare image for overlay
prepare_image() {
    local input_image="$1"
    local output_image="$2"
    local target_size="${3:-300}"  # width or height in pixels
    local keep_aspect="${4:-yes}"
    local add_transparency="${5:-no}"
    local opacity="${6:-1.0}"
    
    check_file "$input_image" "Input image" || return 1
    
    echo "🎨 Preparing image..."
    
    local scale_filter
    if [ "$keep_aspect" == "yes" ]; then
        scale_filter="scale=${target_size}:-1"
    else
        scale_filter="scale=${target_size}:${target_size}"
    fi
    
    local filter="$scale_filter"
    
    if [ "$add_transparency" == "yes" ]; then
        filter="${filter},format=rgba,colorchannelmixer=aa=${opacity}"
    fi
    
    ffmpeg -y -i "$input_image" -vf "$filter" "$output_image"
    
    if [ $? -eq 0 ]; then
        echo "✅ Image prepared: $output_image"; return 0
    else
        echo "❌ Failed to prepare image"; return 1
    fi
}

# Create animated zoom effect on image
create_image_zoom() {
    local image_file="$1"
    local output_video="$2"
    local duration="${3:-5}"
    local zoom_type="${4:-in}"  # in, out, or pan
    local width="${5:-1920}"
    local height="${6:-1080}"
    local fps="${7:-30}"
    
    check_file "$image_file" "Image file" || return 1
    
    echo "🎬 Creating zoom effect on image..."
    
    local zoom_filter
    case "$zoom_type" in
        in) zoom_filter="zoompan=z='min(zoom+0.0015,1.5)':d=${duration}*${fps}:x='iw/2-(iw/zoom/2)':y='ih/2-(ih/zoom/2)':s=${width}x${height}";;
        out) zoom_filter="zoompan=z='if(lte(zoom,1.0),1.5,max(1.001,zoom-0.0015))':d=${duration}*${fps}:x='iw/2-(iw/zoom/2)':y='ih/2-(ih/zoom/2)':s=${width}x${height}";;
        pan) zoom_filter="zoompan=z=1.5:d=${duration}*${fps}:x='iw/2-(iw/zoom/2)':y='if(lte(on,1),ih/2-(ih/zoom/2),y-1)':s=${width}x${height}";;
        *) echo "❌ Unknown zoom type: $zoom_type"; return 1;;
    esac
    
    ffmpeg -y -loop 1 -i "$image_file" \
        -vf "$zoom_filter,format=yuv420p" \
        -t "$duration" -r "$fps" \
        -c:v libx264 -preset medium -crf 23 \
        "$output_video"
    
    if [ $? -eq 0 ]; then
        echo "✅ Zoom video created: $output_video"; return 0;
    else
        echo "❌ Failed to create zoom video"; return 1;
    fi
}

# Create picture-in-picture effect
create_pip_video() {
    local main_video="$1"
    local pip_image="$2"
    local output_video="$3"
    local position="${4:-bottom-right}"
    local scale="${5:-0.25}"
    local opacity="${6:-1.0}"
    local padding="${7:-20}"  # pixels from edge
    
    check_file "$main_video" "Main video" || return 1
    check_file "$pip_image" "PIP image" || return 1
    
    echo "🖼️  Creating picture-in-picture..."
    
    local x_pos y_pos
    case "$position" in
        top-left) x_pos="$padding"; y_pos="$padding" ;;
        top-right) x_pos="main_w-overlay_w-$padding"; y_pos="$padding" ;;
        bottom-left) x_pos="$padding"; y_pos="main_h-overlay_h-$padding" ;;
        *) x_pos="main_w-overlay_w-$padding"; y_pos="main_h-overlay_h-$padding" ;;
    esac
    
    ffmpeg -y -i "$main_video" -i "$pip_image" \
        -filter_complex "[1:v]scale=iw*${scale}:ih*${scale},format=rgba,colorchannelmixer=aa=${opacity}[pip];[0:v][pip]overlay=${x_pos}:${y_pos}" \
        -c:v libx264 -preset medium -crf 23 \
        -c:a copy \
        "$output_video"
    
    if [ $? -eq 0 ]; then
        echo "✅ PIP video created: $output_video"; return 0
    else
        echo "❌ Failed to create PIP video"; return 1
    fi
}

# ==================== VIDEO CREATION FUNCTIONS ====================

# Create basic video with SRT subtitles
create_basic_video() {
    local audio_file="$1"
    local srt_file="$2"
    local output_file="$3"
    local bg_color="${4:-#1a1a2e}"
    local width="${5:-1920}"
    local height="${6:-1080}"
    local fontsize="${7:-24}"
    local margin_v="${8:-50}"
    local font="${9:-$DEFAULT_FONT}"
    local alignment="${10:-2}"
    local outline="${11:-2}"
    local shadow="${12:-0}"
    local image_file="${13}"
    local image_position="${14:-top-right}"
    local image_scale="${15:-0.15}"
    local bg_image="${16}"
    local bg_image_mode="${17:-scale}"

    check_file "$audio_file" "Audio file" || return 1
    check_file "$srt_file" "SRT file" || return 1
    
    local duration=$(get_audio_duration "$audio_file")
    
    echo "🎬 Creating basic video..."
    echo "📐 Resolution: ${width}x${height}"
    
    local ffmpeg_inputs=""
    local filter_complex=""
    local audio_map_idx=1
    local overlay_map_idx=2

    if [ -n "$bg_image" ] && [ -f "$bg_image" ]; then
        echo "🖼️  Using background image: $bg_image (mode: $bg_image_mode)"
        local bg_filter=$(create_background_filter "$bg_image_mode" "$width" "$height")
        ffmpeg_inputs="-loop 1 -i \"$bg_image\" -i \"$audio_file\""
        filter_complex="[0:v]$bg_filter,format=yuv420p[base];"
    else
        echo "🎨 Using background color: $bg_color"
        ffmpeg_inputs="-f lavfi -i color=c=$bg_color:s=${width}x${height}:d=$duration:r=30 -i \"$audio_file\""
        filter_complex="[0:v]format=yuv420p[base];"
    fi

    local abs_srt_file=$(readlink -f "$srt_file" 2>/dev/null || echo "$srt_file")
    local subtitle_style="FontName=${font},FontSize=${fontsize},PrimaryColour=&HFFFFFF,OutlineColour=&H000000,BorderStyle=3,Outline=${outline},Shadow=${shadow},MarginV=${margin_v},Alignment=${alignment}"
    filter_complex="${filter_complex}[base]subtitles='${abs_srt_file}':force_style='${subtitle_style}'[subbed];"
    local current_video_stream="[subbed]"

    if [ -n "$image_file" ] && [ -f "$image_file" ]; then
        echo "🖼️  Adding image overlay: $image_file"
        ffmpeg_inputs="$ffmpeg_inputs -i \"$image_file\""
        local overlay_filter=$(create_overlay_filter_string "$image_position" "$image_scale" "1.0")
        filter_complex="${filter_complex}[${overlay_map_idx}:v]${overlay_filter/\[base\]/$current_video_stream}[v];"
        current_video_stream="[v]"
    fi
    
    filter_complex="${filter_complex%;}" # Remove trailing semicolon if it exists
    
    local ffmpeg_cmd="ffmpeg -y $ffmpeg_inputs -filter_complex \"$filter_complex\" -map \"${current_video_stream}\" -map ${audio_map_idx}:a -c:v libx264 -preset medium -crf 23 -c:a aac -b:a 192k -shortest \"$output_file\""
    
    eval $ffmpeg_cmd
    
    if [ $? -eq 0 ]; then echo "✅ Video created: $output_file"; return 0; else echo "❌ Video creation failed"; return 1; fi
}

# Create karaoke video with ASS subtitles
create_karaoke_video() {
    local audio_file="$1"
    local ass_file="$2"
    local output_file="$3"
    local bg_color="${4:-black}"
    local width="${5:-1920}"
    local height="${6:-1080}"
    local font_dir="${7:-$DEFAULT_FONT_DIR}"
    local preset="${8:-medium}"
    local crf="${9:-23}"
    local fps="${10:-30}"
    local image_file="${11}"
    local image_position="${12:-top-right}"
    local image_scale="${13:-0.15}"
    local bg_image="${14}"
    local bg_image_mode="${15:-scale}"
    
    check_file "$audio_file" "Audio file" || return 1
    check_file "$ass_file" "ASS file" || return 1
    
    local duration=$(get_audio_duration "$audio_file")
    
    echo "🎬 Creating karaoke video..."
    
    local ffmpeg_inputs=""
    local filter_complex=""
    local audio_map_idx=1
    local overlay_map_idx=2

    if [ -n "$bg_image" ] && [ -f "$bg_image" ]; then
        echo "🖼️  Using background image: $bg_image (mode: $bg_image_mode)"
        local bg_filter=$(create_background_filter "$bg_image_mode" "$width" "$height")
        ffmpeg_inputs="-loop 1 -r $fps -i \"$bg_image\" -i \"$audio_file\""
        filter_complex="[0:v]$bg_filter,format=yuv420p[base];"
    else
        echo "🎨 Using background color: $bg_color"
        ffmpeg_inputs="-f lavfi -i color=c=$bg_color:s=${width}x${height}:d=$duration:r=$fps -i \"$audio_file\""
        filter_complex="[0:v]format=yuv420p[base];"
    fi

    local abs_ass_file=$(readlink -f "$ass_file" 2>/dev/null || echo "$ass_file")
    filter_complex="${filter_complex}[base]ass='${abs_ass_file}':fontsdir='${font_dir}'[subbed];"
    local current_video_stream="[subbed]"

    if [ -n "$image_file" ] && [ -f "$image_file" ]; then
        echo "🖼️  Adding image overlay: $image_file"
        ffmpeg_inputs="$ffmpeg_inputs -i \"$image_file\""
        local overlay_filter=$(create_overlay_filter_string "$image_position" "$image_scale" "1.0")
        filter_complex="${filter_complex}[${overlay_map_idx}:v]${overlay_filter/\[base\]/$current_video_stream}[v];"
        current_video_stream="[v]"
    fi

    filter_complex="${filter_complex%;}"

    local ffmpeg_cmd="ffmpeg -y $ffmpeg_inputs -filter_complex \"$filter_complex\" -map \"${current_video_stream}\" -map ${audio_map_idx}:a -c:v libx264 -preset $preset -crf $crf -c:a aac -b:a 192k -shortest \"$output_file\""
    
    eval $ffmpeg_cmd

    if [ $? -eq 0 ]; then echo "✅ Karaoke video created: $output_file"; return 0; else echo "❌ Video creation failed"; return 1; fi
}

# Create modern styled video with enhanced subtitles
create_modern_video() {
    local audio_file="$1"
    local srt_file="$2"
    local format="${3:-youtube}"
    local output_file="$4"
    local bg_color="${5:-#1a1a2e}"
    local font="${6:-Arial Bold}"
    local primary_color="${7:-&HFFFFFF&}"
    local highlight_color="${8:-&HFFFF00&}"
    local preset="${9:-medium}"
    local crf="${10:-23}"
    local image_file="${11}"
    local image_position="${12:-top-right}"
    local image_scale="${13:-0.15}"
    local bg_image="${14}"
    local bg_image_mode="${15:-scale}"

    check_file "$audio_file" "Audio file" || return 1
    check_file "$srt_file" "SRT file" || return 1
    
    local settings=$(get_format_settings "$format")
    if [ "$settings" == "ERROR" ]; then echo "❌ Unknown format: $format"; return 1; fi
    IFS=':' read -r width height fontsize margin_v _ <<< "$settings"
    
    local duration=$(get_audio_duration "$audio_file")
    
    echo "🎬 Creating modern $format video..."
    
    local ffmpeg_inputs=""
    local filter_complex=""
    local audio_map_idx=1
    local overlay_map_idx=2

    if [ -n "$bg_image" ] && [ -f "$bg_image" ]; then
        echo "🖼️  Using background image: $bg_image (mode: $bg_image_mode)"
        local bg_filter=$(create_background_filter "$bg_image_mode" "$width" "$height")
        ffmpeg_inputs="-loop 1 -r 30 -i \"$bg_image\" -i \"$audio_file\""
        filter_complex="[0:v]$bg_filter,format=yuv420p[base];"
    else
        echo "🎨 Using background color: $bg_color"
        ffmpeg_inputs="-f lavfi -i color=c=$bg_color:s=${width}x${height}:d=$duration:r=30 -i \"$audio_file\""
        filter_complex="[0:v]format=yuv420p[base];"
    fi

    local abs_srt_file=$(readlink -f "$srt_file" 2>/dev/null || echo "$srt_file")
    local subtitle_style="FontName=${font},FontSize=${fontsize},PrimaryColour=${primary_color},SecondaryColour=${highlight_color},OutlineColour=&H000000&,BackColour=&H80000000&,Bold=1,BorderStyle=4,Outline=3,Shadow=2,MarginV=${margin_v},MarginL=60,MarginR=60,Alignment=2"
    filter_complex="${filter_complex}[base]subtitles='${abs_srt_file}':force_style='${subtitle_style}'[subbed];"
    local current_video_stream="[subbed]"

    if [ -n "$image_file" ] && [ -f "$image_file" ]; then
        echo "🖼️  Adding image overlay: $image_file"
        ffmpeg_inputs="$ffmpeg_inputs -i \"$image_file\""
        local overlay_filter=$(create_overlay_filter_string "$image_position" "$image_scale" "1.0")
        filter_complex="${filter_complex}[${overlay_map_idx}:v]${overlay_filter/\[base\]/$current_video_stream}[v];"
        current_video_stream="[v]"
    fi
    
    filter_complex="${filter_complex%;}"
    
    local ffmpeg_cmd="ffmpeg -y $ffmpeg_inputs -filter_complex \"$filter_complex\" -map \"${current_video_stream}\" -map ${audio_map_idx}:a -c:v libx264 -preset $preset -crf $crf -c:a aac -b:a 192k -shortest \"$output_file\""

    eval $ffmpeg_cmd
    
    if [ $? -eq 0 ]; then echo "✅ Modern video created: $output_file"; return 0; else echo "❌ Video creation failed"; return 1; fi
}

# ==================== PIPELINE FUNCTIONS ====================

# Full basic pipeline: transcribe + create basic video
pipeline_basic() {
    local audio_file="$1"
    local model="${2:-$DEFAULT_MODEL}"
    local output_dir="${3:-$OUTPUT_DIR}"
    
    mkdir -p "$output_dir"
    local basename=$(get_basename "$audio_file")
    local srt_file="$output_dir/${basename}.srt"
    local output_video="$output_dir/${basename}-video.mp4"
    
    echo "====== STEP 1: TRANSCRIPTION ======"
    srt_file=$(transcribe_to_srt "$audio_file" "$model" "$output_dir") || return 1
    
    echo -e "\n====== STEP 2: VIDEO CREATION ======"
    create_basic_video "$audio_file" "$srt_file" "$output_video" || return 1
    
    echo -e "\n=========================================\n🎉 Basic pipeline complete! Video: $output_video\n========================================="
}

# Full karaoke pipeline: transcribe + generate ASS + create video
pipeline_karaoke() {
    local audio_file="$1"
    local format="${2:-landscape}"
    local model="${3:-$DEFAULT_MODEL}"
    local output_dir="${4:-$OUTPUT_DIR}"
    
    mkdir -p "$output_dir"
    local basename=$(get_basename "$audio_file")
    local json_file="$output_dir/${basename}.json"
    local ass_file="$output_dir/${basename}-karaoke.ass"
    local output_video="$output_dir/${basename}-${format}-karaoke.mp4"
    
    echo "====== STEP 1: TRANSCRIPTION ======"
    json_file=$(transcribe_to_json "$audio_file" "$model" "$output_dir") || return 1
    
    local settings=$(get_format_settings "$format")
    if [ "$settings" == "ERROR" ]; then return 1; fi
    IFS=':' read -r width height _ _ _ <<< "$settings"
    
    echo -e "\n====== STEP 2: ASS GENERATION ======"
    ass_file=$(generate_karaoke_ass "$json_file" "$width" "$height" "$ass_file") || return 1
    
    echo -e "\n====== STEP 3: VIDEO CREATION ======"
    create_karaoke_video "$audio_file" "$ass_file" "$output_video" "black" "$width" "$height" || return 1
    
    echo -e "\n=========================================\n🎉 Karaoke pipeline complete! Video: $output_video\n========================================="
}

# Full modern video pipeline: transcribe + create styled video
pipeline_modern() {
    local audio_file="$1"
    local format="${2:-youtube}"
    local model="${3:-$DEFAULT_MODEL}"
    local output_dir="${4:-$OUTPUT_DIR}"
    local bg_color="${5:-#1a1a2e}"
    
    mkdir -p "$output_dir"
    local basename=$(get_basename "$audio_file")
    local srt_file="$output_dir/${basename}.srt"
    local output_video="$output_dir/${basename}-${format}-modern.mp4"
    
    echo "====== STEP 1: TRANSCRIPTION ======"
    srt_file=$(transcribe_to_srt "$audio_file" "$model" "$output_dir") || return 1
    
    echo -e "\n====== STEP 2: VIDEO CREATION ======"
    create_modern_video "$audio_file" "$srt_file" "$format" "$output_video" "$bg_color" || return 1
    
    echo -e "\n=========================================\n🎉 Modern video pipeline complete! Video: $output_video\n========================================="
}

# Export functions for use in other scripts
export -f get_basename check_file get_audio_duration get_format_settings
export -f create_background_filter create_overlay_filter_string add_logo_to_video prepare_image create_image_zoom create_pip_video
export -f transcribe_to_json transcribe_to_srt generate_karaoke_ass
export -f create_basic_video create_karaoke_video create_modern_video
export -f pipeline_basic pipeline_karaoke pipeline_modern