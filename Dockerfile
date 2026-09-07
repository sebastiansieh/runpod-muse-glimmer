FROM ghcr.io/ggml-org/llama.cpp:server-cuda

# The llama.cpp server image sets ENTRYPOINT=/app/llama-server; reset it so our
# own start script controls the container command.
ENTRYPOINT []

WORKDIR /app

# ---- BAKED MODEL ----
# Downloaded early so it stays cached across unrelated changes below.
# Qwen3.6-35B-A3B (MoE, 35B total / ~3B active per token), IQ4_NL quant.
# The 19.3GB file can't be committed to git (2GB limit), so we fetch it at
# build time (CI runners have fast networking).
RUN curl -L --fail --retry 3 -o /app/Qwen_Qwen3.6-35B-A3B-IQ4_NL.gguf \
    https://huggingface.co/bartowski/Qwen_Qwen3.6-35B-A3B-GGUF/resolve/main/Qwen_Qwen3.6-35B-A3B-IQ4_NL.gguf \
    && ls -lh /app/Qwen_Qwen3.6-35B-A3B-IQ4_NL.gguf

COPY start.sh .
RUN chmod +x start.sh

ENV MODEL_FILE=Qwen_Qwen3.6-35B-A3B-IQ4_NL.gguf
ENV LLAMA_PORT=8000
ENV CTX_SIZE=65536
# Number of layers whose MoE expert weights are kept in system RAM instead of
# VRAM, so the ~19.3GB model fits a 16GB GPU (e.g. Azure Container Apps T4).
# Tune via env var on the Container App revision without rebuilding:
# lower this until VRAM spills, then back off one step.
ENV N_CPU_MOE=10

EXPOSE 8000