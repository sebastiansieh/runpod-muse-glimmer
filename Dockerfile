FROM ghcr.io/ggml-org/llama.cpp:server-cuda

RUN apt-get update && apt-get install -y --no-install-recommends \
    python3 \
    python3-pip \
    curl \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /app

COPY requirements.txt .
RUN pip3 install --no-cache-dir --break-system-packages -r requirements.txt

COPY handler.py .

ENV MODEL_DIR=/runpod-volume/models
ENV MODEL_FILE=Muse-Glimmer-30B-UD-Q4_K_XL.gguf
ENV MODEL_URL=https://huggingface.co/unsloth/Muse-Glimmer-30B-GGUF/resolve/main/Muse-Glimmer-30B-UD-Q4_K_XL.gguf
ENV LLAMA_PORT=8000
ENV CTX_SIZE=65536

CMD ["python3", "-u", "handler.py"]
