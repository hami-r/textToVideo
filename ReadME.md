# Whisper.cpp + FFmpeg Development Environment

A persistent Docker environment for audio transcription and narration video creation.

## 🏗️ Project Structure

```
project/
├── docker-compose.yml
├── README.md
├── input/                 # Place your audio files here
│   └── audio.wav
├── output/                # Transcripts and videos appear here
└── scripts/               # Helper scripts
    ├── transcribe.sh
    ├── create-narration-video.sh
    └── full-pipeline.sh
```

## 🚀 Quick Start

### 1. Create the scripts folder
```bash
mkdir -p input output scripts
```

### 2. Start the environment
```bash
docker-compose up -d
```

The container will:
- Install whisper.cpp, ffmpeg, and dependencies
- Stay running in the background
- Be ready for your commands

### 3. Download a Whisper model (first time only)
```bash
docker exec -it whisper-dev bash /opt/whisper.cpp/models/download-ggml-model.sh base.en
```

Available models: `tiny.en`, `base.en`, `small.en`, `medium.en`, `large-v1`, `large-v2`, `large-v3`

### 4. Place your audio in `input/` folder
```bash
cp your-audio.wav input/
```

## 🎯 Usage

### Option A: Full Pipeline (Recommended)
Transcribe + create video in one command:
```bash
docker exec -it whisper-dev bash scripts/full-pipeline.sh input/audio.wav
```

### Option B: Step by Step

**Step 1: Transcribe audio**
```bash
docker exec -it whisper-dev bash scripts/transcribe.sh input/audio.wav
```

**Step 2: Create narration video**
```bash
docker exec -it whisper-dev bash scripts/create-narration-video.sh input/audio.wav
```

### Option C: Interactive Shell
For development and testing:
```bash
docker exec -it whisper-dev bash
```

Then inside the container:
```bash
# Transcribe
whisper -m models/ggml-base.en.bin -f input/audio.wav -osrt -of output/audio

# Create video manually
ffmpeg -f lavfi -i color=c=#1a1a2e:s=1920x1080:d=60 -i input/audio.wav \
  -vf "subtitles=output/audio.srt" -shortest output/video.mp4
```

## 🎨 Customization

### Change background color
```bash
docker exec -it whisper-dev bash scripts/create-narration-video.sh \
  input/audio.wav output/audio.srt output/video.mp4 "#000000"
```

### Use different model
```bash
docker exec -it whisper-dev bash scripts/transcribe.sh \
  input/audio.wav models/ggml-small.en.bin
```

## 🛠️ Management

### View logs
```bash
docker-compose logs -f
```

### Stop environment
```bash
docker-compose down
```

### Restart environment
```bash
docker-compose restart
```

### Remove everything (including models)
```bash
docker-compose down -v
```

## 📋 Output Files

After running the pipeline, you'll get:
- `output/audio.srt` - Timestamped subtitles
- `output/narration-video.mp4` - Video with burned-in subtitles

## 💡 Tips

- The container stays running - no need to start it each time
- Models are cached in a Docker volume (persist between restarts)
- Scripts have execute permissions automatically
- Use larger models (small, medium) for better accuracy
- Background color can be customized (hex format: #RRGGBB)

## 🔍 Troubleshooting

**Container not running?**
```bash
docker-compose ps
docker-compose up -d
```

**Model not found?**
```bash
docker exec -it whisper-dev ls -la models/
```

**Permission issues?**
```bash
chmod +x scripts/*.sh
```

**Check if whisper.cpp is built:**
```bash
docker exec -it whisper-dev which whisper
```