#!/bin/bash
# Transcribe audio with whisper.cpp and generate SRT subtitles

INPUT_FILE="${1:-input/audio.wav}"
MODEL="${2:-/opt/whisper.cpp/models/ggml-base.en.bin}"
OUTPUT_DIR="output"

if [ ! -f "$INPUT_FILE" ]; then
    echo "❌ Input file not found: $INPUT_FILE"
    exit 1
fi

if [ ! -f "$MODEL" ]; then
    echo "❌ Model not found: $MODEL"
    echo "💡 Download it with: bash /opt/whisper.cpp/models/download-ggml-model.sh base.en"
    exit 1
fi

echo "🎤 Transcribing: $INPUT_FILE"
echo "📦 Using model: $MODEL"

# Get base filename without extension
BASENAME=$(basename "$INPUT_FILE" | sed 's/\.[^.]*$//')

# Run whisper to generate SRT file
/opt/whisper.cpp/build/bin/whisper-cli -m "$MODEL" -f "$INPUT_FILE" -osrt -of "$OUTPUT_DIR/$BASENAME"

if [ $? -eq 0 ]; then
    echo "✅ Transcription complete!"
    echo "📄 SRT file: $OUTPUT_DIR/${BASENAME}.srt"
else
    echo "❌ Transcription failed"
    exit 1
fi