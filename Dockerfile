FROM ghcr.io/ggml-org/llama.cpp:server-cuda

# The llama.cpp server image sets ENTRYPOINT=/app/llama-server, which would
# hijack our CMD (python3 -u handler.py) and fail with "invalid argument: python3".
ENTRYPOINT []

WORKDIR /app

# ---- BAKED MODEL ----
# Downloaded early so it stays cached across unrelated code changes below.
# The GGUF ships inside the image so workers need no network volume and can
# run in any datacenter. Downloaded at build time (CI runners have fast
# networking); the 15.88GB file can't be committed to git (2GB limit).
RUN curl -L --fail --retry 3 -o /app/Muse-Glimmer-30B-UD-Q4_K_XL.gguf \
    https://huggingface.co/unsloth/Muse-Glimmer-30B-GGUF/resolve/main/Muse-Glimmer-30B-UD-Q4_K_XL.gguf \
    && ls -lh /app/Muse-Glimmer-30B-UD-Q4_K_XL.gguf

RUN apt-get update && apt-get install -y --no-install-recommends \
    python3 \
    python3-pip \
    curl \
    && rm -rf /var/lib/apt/lists/*

COPY requirements.txt .
RUN pip3 install --no-cache-dir --break-system-packages -r requirements.txt

COPY handler.py .

ENV MODEL_DIR=/app
ENV MODEL_FILE=Muse-Glimmer-30B-UD-Q4_K_XL.gguf
ENV MODEL_URL=https://huggingface.co/unsloth/Muse-Glimmer-30B-GGUF/resolve/main/Muse-Glimmer-30B-UD-Q4_K_XL.gguf
ENV LLAMA_PORT=8000
ENV CTX_SIZE=65536

CMD ["python3", "-u", "handler.py"]
