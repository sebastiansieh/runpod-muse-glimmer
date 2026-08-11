import os
import subprocess
import time

import requests
import runpod

MODEL_DIR = os.environ.get("MODEL_DIR", "/runpod-volume/models")
MODEL_FILE = os.environ.get("MODEL_FILE", "Muse-Glimmer-30B-UD-Q4_K_XL.gguf")
MODEL_URL = os.environ.get("MODEL_URL")
LLAMA_PORT = os.environ.get("LLAMA_PORT", "8000")
CTX_SIZE = os.environ.get("CTX_SIZE", "65536")
LLAMA_BASE_URL = f"http://127.0.0.1:{LLAMA_PORT}"

MODEL_PATH = os.path.join(MODEL_DIR, MODEL_FILE)


def ensure_model():
    os.makedirs(MODEL_DIR, exist_ok=True)
    if os.path.exists(MODEL_PATH):
        print(f"Model already present at {MODEL_PATH}", flush=True)
        return

    tmp_path = MODEL_PATH + ".part"
    print(f"Downloading model from {MODEL_URL} ...", flush=True)
    with requests.get(MODEL_URL, stream=True, timeout=None) as r:
        r.raise_for_status()
        with open(tmp_path, "wb") as f:
            for chunk in r.iter_content(chunk_size=1024 * 1024 * 8):
                if chunk:
                    f.write(chunk)
    os.rename(tmp_path, MODEL_PATH)
    print("Model download complete.", flush=True)


def start_llama_server():
    cmd = [
        "/app/llama-server",
        "--model", MODEL_PATH,
        "--host", "127.0.0.1",
        "--port", LLAMA_PORT,
        "--ctx-size", CTX_SIZE,
        "--n-gpu-layers", "999",
        "--flash-attn", "on",
    ]
    print(f"Starting llama-server: {' '.join(cmd)}", flush=True)
    proc = subprocess.Popen(cmd)

    for _ in range(600):
        try:
            resp = requests.get(f"{LLAMA_BASE_URL}/health", timeout=3)
            if resp.status_code == 200:
                print("llama-server is ready.", flush=True)
                return proc
        except requests.exceptions.RequestException:
            pass
        if proc.poll() is not None:
            raise RuntimeError("llama-server exited before becoming ready")
        time.sleep(1)
    raise RuntimeError("llama-server did not become ready in time")


def handler(job):
    job_input = job.get("input", {})
    openai_route = job_input.get("openai_route")
    openai_input = job_input.get("openai_input")

    if openai_route is None or openai_input is None:
        return {"error": "This endpoint only supports the /openai/... route."}

    url = f"{LLAMA_BASE_URL}{openai_route}"
    stream = bool(openai_input.get("stream", False))

    if not stream:
        resp = requests.post(url, json=openai_input, timeout=600)
        resp.raise_for_status()
        return resp.json()

    def stream_generator():
        with requests.post(url, json=openai_input, stream=True, timeout=600) as resp:
            resp.raise_for_status()
            for line in resp.iter_lines(decode_unicode=True):
                if line is None:
                    continue
                yield line + "\n"

    return stream_generator()


ensure_model()
start_llama_server()

runpod.serverless.start({"handler": handler, "return_aggregate_stream": True})
