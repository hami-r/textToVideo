FROM ubuntu:22.04

WORKDIR /opt

RUN apt-get update && \
    apt-get install -y git build-essential cmake ffmpeg wget python3 && \
    git clone https://github.com/ggerganov/whisper.cpp.git && \
    cd whisper.cpp && \
    cmake -B build && cmake --build build --config Release && \
    ln -sf /opt/whisper.cpp/build/bin/whisper-cli /usr/local/bin/whisper && \
    echo "✅ whisper.cpp built successfully"

WORKDIR /workspace
