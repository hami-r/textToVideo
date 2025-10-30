#!/bin/bash
# Full pipeline: transcribe audio and create narration video

AUDIO_FILE="${1:-input/audio.wav}"
MODEL="${2:-models/ggml-base.en.bin}"

echo "🚀 Starting full pipeline..."
echo "================================"

# Step 1: Transcribe
echo "📝 Step 1: Transcribing audio..."
bash /workspace/scripts/transcribe.sh "$AUDIO_FILE" "$MODEL"

if [ $? -ne 0 ]; then
    echo "❌ Pipeline failed at transcription step"
    exit 1
fi

echo ""
echo "================================"

# Step 2: Create video
echo "🎬 Step 2: Creating narration video..."
bash /workspace/scripts/create-narration-video.sh "$AUDIO_FILE"

if [ $? -eq 0 ]; then
    echo ""
    echo "================================"
    echo "🎉 Pipeline complete!"
    echo "✅ All done! Check the output folder."
else
    echo "❌ Pipeline failed at video creation step"
    exit 1
fi