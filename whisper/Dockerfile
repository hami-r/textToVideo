FROM debian:bookworm-slim

ENV DEBIAN_FRONTEND=noninteractive

RUN apt-get update && apt-get install -y \
    git \
    build-essential \
    cmake \
    wget \
    curl \
    ca-certificates \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /app

RUN git clone https://github.com/ggerganov/whisper.cpp.git .
RUN make

RUN bash ./models/download-ggml-model.sh large-v3

VOLUME ["/audio", "/output", "/app/models"]

CMD ["bash"]
