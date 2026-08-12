#!/bin/sh
set -e

exec /app/llama-server \
    --model "/app/${MODEL_FILE}" \
    --host 0.0.0.0 \
    --port "${LLAMA_PORT}" \
    --ctx-size "${CTX_SIZE}" \
    --n-gpu-layers 999 \
    --n-cpu-moe "${N_CPU_MOE}" \
    --flash-attn on
