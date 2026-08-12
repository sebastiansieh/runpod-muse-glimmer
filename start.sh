#!/bin/sh
set -e

if [ -z "$LLAMA_API_KEY" ]; then
    echo "FATAL: LLAMA_API_KEY is not set. This service is exposed to the" >&2
    echo "public internet and must not start without an API key configured." >&2
    echo "Set it as a secret on the Azure Container App and reference it" >&2
    echo "as an env var (see README)." >&2
    exit 1
fi

exec /app/llama-server \
    --model "/app/${MODEL_FILE}" \
    --host 0.0.0.0 \
    --port "${LLAMA_PORT}" \
    --ctx-size "${CTX_SIZE}" \
    --n-gpu-layers 999 \
    --n-cpu-moe "${N_CPU_MOE}" \
    --flash-attn on \
    --api-key "${LLAMA_API_KEY}"
