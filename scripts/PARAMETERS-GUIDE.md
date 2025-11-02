# Video Library Parameters Guide

Complete guide to all configurable parameters in video-lib.sh

## 🌍 Global Environment Variables

Set these **before** sourcing the library:

```bash
# Whisper model path
export WHISPER_MODEL="/opt/whisper.cpp/models/ggml-small.en.bin"

# Output directory
export VIDEO_OUTPUT_DIR="my-output"

# Whisper CLI path
export WHISPER_CLI_PATH="/custom/path/to/whisper-cli"

# Default font
export VIDEO_FONT="Helvetica"

# Font directory for karaoke
export VIDEO_FONT_DIR="/usr/share/fonts/custom"

# Then source the library
source scripts/video-lib.sh
```

## 📝 Function Parameters Reference

### 1. transcribe_to_json()

```bash
transcribe_to_json <audio_file> [model] [output_dir]
```

| Parameter | Required | Default | Description |
|-----------|----------|---------|-------------|
| audio_file | ✅ Yes | - | Path to audio file |
| model | ❌ No | DEFAULT_MODEL | Whisper model path |
| output_dir | ❌ No | OUTPUT_DIR | Output directory |

**Examples:**
```bash
# Basic
transcribe_to_json "input/audio.wav"

# Custom model
transcribe_to_json "input/audio.wav" "/opt/whisper.cpp/models/ggml-large-v3.bin"

# Custom output
transcribe_to_json "input/audio.wav" "$DEFAULT_MODEL" "output/project1"
```

---

### 2. transcribe_to_srt()

```bash
transcribe_to_srt <audio_file> [model] [output_dir]
```

Same parameters as `transcribe_to_json()`

---

### 3. generate_karaoke_ass()

```bash
generate_karaoke_ass <json_file> <width> <height> <output_ass>
```

| Parameter | Required | Default | Description |
|-----------|----------|---------|-------------|
| json_file | ✅ Yes | - | Whisper JSON output |
| width | ✅ Yes | - | Video width (e.g., 1920) |
| height | ✅ Yes | - | Video height (e.g., 1080) |
| output_ass | ✅ Yes | - | Output ASS file path |

**Font size & margins are auto-calculated based on dimensions**

**Examples:**
```bash
# Landscape
generate_karaoke_ass "output/audio.json" 1920 1080 "output/karaoke.ass"

# Portrait (Reels)
generate_karaoke_ass "output/audio.json" 1080 1920 "output/karaoke.ass"
```

---

### 4. create_basic_video()

```bash
create_basic_video <audio> <srt> <output> [bg_color] [width] [height] \
                   [fontsize] [margin_v] [font] [alignment] [outline] [shadow]
```

| Parameter | Required | Default | Description |
|-----------|----------|---------|-------------|
| audio_file | ✅ Yes | - | Audio file path |
| srt_file | ✅ Yes | - | SRT subtitle file |
| output_file | ✅ Yes | - | Output video path |
| bg_color | ❌ No | #1a1a2e | Background color (hex) |
| width | ❌ No | 1920 | Video width |
| height | ❌ No | 1080 | Video height |
| fontsize | ❌ No | 24 | Subtitle font size |
| margin_v | ❌ No | 50 | Vertical margin |
| font | ❌ No | DEFAULT_FONT | Font name |
| alignment | ❌ No | 2 | Text alignment (2=bottom, 5=center, 8=top) |
| outline | ❌ No | 2 | Text outline width |
| shadow | ❌ No | 0 | Shadow offset |

**Examples:**
```bash
# Basic (1920x1080, default styling)
create_basic_video "audio.wav" "audio.srt" "output.mp4"

# Custom background
create_basic_video "audio.wav" "audio.srt" "output.mp4" "#000000"

# Vertical video
create_basic_video "audio.wav" "audio.srt" "output.mp4" "#1a1a2e" 1080 1920

# Custom font and size
create_basic_video "audio.wav" "audio.srt" "output.mp4" "#1a1a2e" 1920 1080 32

# Full customization
create_basic_video "audio.wav" "audio.srt" "output.mp4" \
    "#1a1a2e" 1920 1080 32 100 "Helvetica" 2 3 1
```

**Alignment values:**
- `1` = Bottom left
- `2` = Bottom center (default)
- `3` = Bottom right
- `5` = Center
- `8` = Top center

---

### 5. create_karaoke_video()

```bash
create_karaoke_video <audio> <ass> <output> [bg_color] [width] [height] \
                     [font_dir] [preset] [crf] [fps]
```

| Parameter | Required | Default | Description |
|-----------|----------|---------|-------------|
| audio_file | ✅ Yes | - | Audio file path |
| ass_file | ✅ Yes | - | ASS subtitle file |
| output_file | ✅ Yes | - | Output video path |
| bg_color | ❌ No | black | Background color |
| width | ❌ No | 1920 | Video width |
| height | ❌ No | 1080 | Video height |
| font_dir | ❌ No | DEFAULT_FONT_DIR | Font directory path |
| preset | ❌ No | medium | FFmpeg preset (speed/quality) |
| crf | ❌ No | 23 | Quality (0-51, lower=better) |
| fps | ❌ No | 30 | Frame rate |

**FFmpeg Presets (speed vs quality):**
- `ultrafast` - Fastest, lowest quality
- `superfast`
- `veryfast`
- `faster`
- `fast`
- `medium` - Balanced (default)
- `slow`
- `slower`
- `veryslow` - Slowest, best quality

**CRF Values:**
- `18-22` - High quality (larger files)
- `23` - Default, good balance
- `28-32` - Lower quality (smaller files)

**Examples:**
```bash
# Basic
create_karaoke_video "audio.wav" "karaoke.ass" "output.mp4"

# Portrait with custom background
create_karaoke_video "audio.wav" "karaoke.ass" "output.mp4" "#2c3e50" 1080 1920

# High quality, slower encoding
create_karaoke_video "audio.wav" "karaoke.ass" "output.mp4" \
    "black" 1920 1080 "$DEFAULT_FONT_DIR" "slow" 18

# Fast encoding, lower quality
create_karaoke_video "audio.wav" "karaoke.ass" "output.mp4" \
    "black" 1920 1080 "$DEFAULT_FONT_DIR" "veryfast" 28

# 60fps video
create_karaoke_video "audio.wav" "karaoke.ass" "output.mp4" \
    "black" 1920 1080 "$DEFAULT_FONT_DIR" "medium" 23 60
```

---

### 6. create_modern_video()

```bash
create_modern_video <audio> <srt> <format> <output> [bg_color] \
                    [font] [primary_color] [highlight_color] [preset] [crf]
```

| Parameter | Required | Default | Description |
|-----------|----------|---------|-------------|
| audio_file | ✅ Yes | - | Audio file path |
| srt_file | ✅ Yes | - | SRT subtitle file |
| format | ✅ Yes | youtube | Format preset (see below) |
| output_file | ✅ Yes | - | Output video path |
| bg_color | ❌ No | #1a1a2e | Background color |
| font | ❌ No | Arial Bold | Font name |
| primary_color | ❌ No | &HFFFFFF& | Main text color (ASS hex) |
| highlight_color | ❌ No | &HFFFF00& | Highlight color (ASS hex) |
| preset | ❌ No | medium | FFmpeg preset |
| crf | ❌ No | 23 | Quality setting |

**Format Presets:**
- `reels` - Instagram Reels (1080x1920, 9:16)
- `story` - Instagram Story (1080x1920, 9:16)
- `tiktok` - TikTok (1080x1920, 9:16)
- `youtube` - YouTube (1920x1080, 16:9)
- `facebook` - Facebook Square (1080x1080, 1:1)
- `square` - Generic Square (1080x1080, 1:1)
- `landscape` - Landscape (1920x1080, 16:9)

**ASS Color Format:**
Colors use format `&HBBGGRR&` (reverse RGB in hex):
- White: `&HFFFFFF&`
- Yellow: `&H00FFFF&` or `&HFFFF00&`
- Red: `&H0000FF&`
- Green: `&H00FF00&`
- Blue: `&HFF0000&`
- Black: `&H000000&`

**Examples:**
```bash
# Basic Instagram Reels
create_modern_video "audio.wav" "audio.srt" "reels" "output.mp4"

# YouTube with dark background
create_modern_video "audio.wav" "audio.srt" "youtube" "output.mp4" "#000000"

# Custom font
create_modern_video "audio.wav" "audio.srt" "youtube" "output.mp4" \
    "#1a1a2e" "Helvetica Bold"

# Custom colors (white text, cyan highlight)
create_modern_video "audio.wav" "audio.srt" "reels" "output.mp4" \
    "#1a1a2e" "Arial Bold" "&HFFFFFF&" "&HFFFF00&"

# High quality YouTube
create_modern_video "audio.wav" "audio.srt" "youtube" "output.mp4" \
    "#1a1a2e" "Arial Bold" "&HFFFFFF&" "&HFFFF00&" "slow" 18
```

---

### 7. Pipeline Functions

#### pipeline_basic()

```bash
pipeline_basic <audio_file> [model] [output_dir]
```

Creates basic 1920x1080 video with standard subtitles.

#### pipeline_modern()

```bash
pipeline_modern <audio_file> [format] [model] [output_dir] [bg_color]
```

| Parameter | Required | Default | Description |
|-----------|----------|---------|-------------|
| audio_file | ✅ Yes | - | Audio file path |
| format | ❌ No | youtube | Format preset |
| model | ❌ No | DEFAULT_MODEL | Whisper model |
| output_dir | ❌ No | OUTPUT_DIR | Output directory |
| bg_color | ❌ No | #1a1a2e | Background color |

#### pipeline_karaoke()

```bash
pipeline_karaoke <audio_file> [format] [model] [output_dir]
```

Same as `pipeline_modern()` but without bg_color (always uses black).

**Pipeline Examples:**
```bash
# Quick YouTube video
pipeline_modern "input/audio.wav"

# Instagram Reels
pipeline_modern "input/audio.wav" "reels"

# Custom output directory
pipeline_modern "input/audio.wav" "youtube" "$DEFAULT_MODEL" "output/project1"

# With custom model and background
pipeline_modern "input/audio.wav" "reels" \
    "/opt/whisper.cpp/models/ggml-small.en.bin" "output" "#000000"

# Karaoke
pipeline_karaoke "input/audio.wav" "landscape"
```

---

## 🎨 Complete Customization Examples

### Example 1: High-Quality YouTube Video

```bash
# Set global preferences
export WHISPER_MODEL="/opt/whisper.cpp/models/ggml-small.en.bin"
export VIDEO_FONT="Helvetica"
source scripts/video-lib.sh

# Transcribe
srt=$(transcribe_to_srt "input/audio.wav" "$WHISPER_MODEL")

# Create video with custom settings
create_modern_video \
    "input/audio.wav" \
    "$srt" \
    "youtube" \
    "output/premium-video.mp4" \
    "#0a0a0a" \
    "Helvetica Bold" \
    "&HFFFFFF&" \
    "&H00D4FF&" \
    "slow" \
    18
```

### Example 2: Fast Processing for Testing

```bash
source scripts/video-lib.sh

# Quick transcribe with tiny model
json=$(transcribe_to_json "input/test.wav" \
    "/opt/whisper.cpp/models/ggml-tiny.en.bin")

# Generate ASS
ass=$(generate_karaoke_ass "$json" 1920 1080 "output/test.ass")

# Fast video creation
create_karaoke_video "input/test.wav" "$ass" "output/test.mp4" \
    "black" 1920 1080 "$DEFAULT_FONT_DIR" "ultrafast" 28
```

### Example 3: Batch with Different Settings

```bash
source scripts/video-lib.sh

for audio in input/*.wav; do
    basename=$(get_basename "$audio")
    
    # Transcribe once
    srt=$(transcribe_to_srt "$audio")
    
    # Create multiple versions
    # Low quality for preview
    create_modern_video "$audio" "$srt" "youtube" \
        "output/${basename}-preview.mp4" "#1a1a2e" \
        "Arial Bold" "&HFFFFFF&" "&HFFFF00&" "veryfast" 28
    
    # High quality for final
    create_modern_video "$audio" "$srt" "youtube" \
        "output/${basename}-final.mp4" "#000000" \
        "Helvetica Bold" "&HFFFFFF&" "&H00D4FF&" "slow" 18
done
```

---

## 📊 Quick Reference Table

| Setting | Options | Impact |
|---------|---------|--------|
| **Preset** | ultrafast → veryslow | Speed vs Quality |
| **CRF** | 0 (best) → 51 (worst) | File size vs Quality |
| **FPS** | 24, 30, 60 | Smoothness vs File size |
| **Font Size** | 24-72 | Readability vs space |
| **Format** | reels, youtube, etc | Dimensions & margins |

## ⚡ Performance Tips

1. **For previews**: Use `veryfast` preset and CRF `28`
2. **For production**: Use `slow` preset and CRF `18-20`
3. **For web**: Use `medium` preset and CRF `23` (default)
4. **For storage**: Use `veryslow` preset and CRF `18`

## 🐛 Common Issues

**"Font not found"**: Set custom font directory
```bash
export VIDEO_FONT_DIR="/usr/share/fonts/truetype/liberation"
```

**Large file sizes**: Increase CRF value (23 → 28)

**Slow encoding**: Use faster preset (medium → fast)

**Poor quality**: Decrease CRF (23 → 18) or use slower preset